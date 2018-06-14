class ApplicationController < ActionController::Base
  layout :main

  protect_from_forgery
  
  @request_start_time = 0
  @request_end_time = 0

  include Auth::ControllerAuthentication
  include PasswordChange
  include TOU::Acceptance

  before_filter :login_required
  before_filter :password_change unless Setting.SSO_AD
  before_filter :acceptance_required if Setting.TOU
  before_filter :expired_session?
  before_filter :check_stix_permission
  before_filter :preprocess_date_params
  before_filter :store_target_location
  before_filter :isa_params, only: [:create,:update]
  before_filter :set_request_start_time
  before_filter :set_no_cache
  before_filter :update_and_log_pool_stats if Setting.DATABASE_POOL_LOGGING_ENABLED
  after_filter :set_csrf_cookie_for_ng
  after_filter :record_api_event
  after_filter :clear_audit_justification
  after_filter :set_request_end_time
  after_filter :update_and_log_pool_stats if Setting.DATABASE_POOL_LOGGING_ENABLED

  unless Rails.env == 'development' || Rails.env == 'test'
    rescue_from Exception do |e|
      ExceptionLogger.debug("exception: #{e}, message: #{e.message}, backtrace: #{e.backtrace}")
      render json: {error: 'Invalid Request'}, status: 400
    end
  end

  # -- Background Stix Marking creation for ingest
  if Setting.PENDING_MARKING_FREQUENCY_IN_SECONDS && Setting.PENDING_MARKING_FREQUENCY_IN_SECONDS>0
    @currently_marking = false
    marking_scheduler = Rufus::Scheduler.new
    marking_scheduler.every "#{Setting.PENDING_MARKING_FREQUENCY_IN_SECONDS}s" do
      begin
        PendingMarkingLogger.debug("Starting processing of pending markings...")
        if @currently_marking
          PendingMarkingLogger.debug("Another marking process currently running...")
        else
          @currently_marking = true
          
          pendings = PendingMarking.limit(100)
          PendingMarkingLogger.debug("Processing #{pendings.size} pending markings")
          
          pendings.each {|x| 
            begin
              if x.object.present?
                x.object.class.apply_default_policy_if_needed(x.object)
              end
              x.destroy
            rescue
              PendingMarkingLogger.debug("Problem applying default marking to #{x.object.class} #{x.object.id}")
            end
          }

          @currently_marking = false
          PendingMarkingLogger.debug("Completed processing of pending markings")
        end
      ensure
        ActiveRecord::Base.clear_active_connections!
      end
    end
  else
    PendingMarkingLogger.debug("PENDING MARKINGS NOT ENABLED")
  end
  
  # -- END Background Stix Marking creation for ingest
  
  # -- SOLR Indexing

  if Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS && Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS>0
    @currently_reindexing = false
    @solr_index_since = SolrIndexTime.first
    if @solr_index_since == nil
      @solr_index_since = SolrIndexTime.create(:last_updated => DateTime.now - 10.minutes)
    end
    all_models = Dir[Rails.root.join('app/models/*.rb')].map {|f| File.basename(f, '.*').camelize.constantize }
    @models = []
    all_models.each do |model|
      if model.superclass==ActiveRecord::Base && model.searchable?
        @models.push(model.to_s)
      end
    end
    scheduler = Rufus::Scheduler.new
    scheduler.every "#{Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS}s" do
      begin
        SolrIndexingLogger.debug("Starting indexing...")
        if @currently_reindexing
          SolrIndexingLogger.debug("Another index currently running...")
        else
          @currently_reindexing = true

          new_time = DateTime.now

          failure = false
          @models.each do |m|
            unless failure
              model=m.constantize
              model.where('updated_at > ?', @solr_index_since.last_updated - 1.second).reorder(nil).find_in_batches do |batch|
                if batch.length > 0
                  begin
                    Sunspot.index(batch)
                    SolrIndexingLogger.debug("  Indexed #{batch.count} #{model.to_s} records")
                  rescue
                    SolrIndexingLogger.error("Error updating SOLR for #{model.to_s}")
                    failure = true
                  end
                  unless failure
                    SolrIndexingLogger.debug("  Completed indexing #{model.to_s}")
                  end
                end
              end
            end
          end
          unless failure
            @solr_index_since.last_updated = new_time
            @solr_index_since.save!
          end
          @currently_reindexing = false
          SolrIndexingLogger.debug("Finished indexing...")
        end
      ensure
        ActiveRecord::Base.clear_active_connections!
      end
    end
  else
    SolrIndexingLogger.debug("INDEXING NOT ENABLED")
  end

  # -- END SOLR Indexing

  def set_csrf_cookie_for_ng
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def store_target_location
    return if session[:user_id]
    session[:return_to] = request.url
  end

  def check_stix_permission
    render json: {errors: ["You do not have the ability to view stix data"]}, status: 403 unless User.has_permission(current_user, 'view_stix_data')
  end

  protected

  def verified_request?
    super || valid_authenticity_token?(session, request.headers['X-XSRF-TOKEN'])
  end
  
  def sanitize_sort_order(column_names, order)
    column_names.each do |column|
      return column if column == order
    end
    return 'updated_at'
  end
  
  def sanitize_sort_direction(direction)
    direction.downcase! if direction.present?
    direction == 'asc' ? 'asc' : 'desc'
  end

  def apply_sort(arel,params)
    return arel unless params[:column] && params[:direction]

    begin
      klass = arel.table.engine
      table = klass.table_name
      column = params[:column]
      direction = params[:direction]

      if ActiveRecord::Base.connection.instance_values["config"][:adapter] == 'postgresql'
        order_by="CAST(nullif(#{column}, '') AS integer)"
      elsif ActiveRecord::Base.connection.instance_values["config"][:adapter] == 'sqlite3'
        order_by="CAST(#{column} AS DECIMAL)"
      else
        order_by="regexp_substr(#{column}, '^\D*') nulls first, to_number(regexp_substr(#{column}, '^[0-9]+'))"
      end

      if (column.downcase == 'port' || column.downcase.include?(' port')) &&
          (direction.downcase == 'asc' || direction.downcase == 'desc')
				arel.reorder("#{order_by} #{direction}")
      elsif klass.column_names.include?(column.to_s.split('.').last) &&
          (direction.downcase == 'asc' || direction.downcase == 'desc')
				arel.reorder(column.to_sym => direction.to_sym)
      # Special sorting required for Uri associated with Link
      elsif table=='cybox_links' && column == 'cybox_uris.uri_normalized' &&
          (direction.downcase == 'asc' || direction.downcase == 'desc')
        arel.reorder(column.to_sym => direction.to_sym)
      end

    rescue NoMethodError #Protecting against SQL Injection
      ExceptionLogger.debug("exception: NoMethodError, message: Protecting against SQL Injection.")
      arel
    end
  end

  def record_limit(limit)
    if limit.present? and limit!=0
      if should_user_be_throttled? && (limit<0 or limit>Setting.DEFAULT_MAX_RECORDS)
        limit=Setting.DEFAULT_MAX_RECORDS
      end
    else
      limit=Setting.DEFAULT_MAX_RECORDS
    end
    return limit
  end

  protected

  def main
    "layouts/application"
  end

  def includes_indicators(arel)
    return unless arel.present?
    arel.includes(indicators: [{observables: [:address,{file: :file_hashes},:mutex,
                                             :dns_record,:domain,{email_message: [:links, :uris]},:http_session, :hostname, :port,
                                             :network_connection,{registry: :registry_values},
                                             :uri,link: :uri]},
                               :confidences,
                               :related_to_objects,
                               :related_by_objects,
                               :kill_chains,
                               :kill_chain_phases,
                               stix_markings: [
                                   :isa_marking_structure,
                                   :tlp_marking_structure,
                                   :simple_marking_structure,
                                   {isa_assertion_structure: [:isa_privs,:further_sharings]}]
                               ])
  end

  def get_request_start_time
    return self.request_start_time
  end
  
  def get_request_end_time
    return self.request_end_time
  end

  def gfi_permitted?
    defined?(Setting.CLASSIFICATION) && Setting.CLASSIFICATION
  end
  
  private

  def set_no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
  
  def clear_audit_justification
    if Audit.justification.present?
      Audit.justification = ''
    end
  end

  def preprocess_date_params
    return unless params[:ebt] && params[:iet]

    begin
      params[:ebt] = params[:ebt].to_datetime
      params[:iet] = params[:iet].to_datetime
      params[:iet] = params[:iet].end_of_day if params[:iet].present? &&
          params[:iet].is_a?(DateTime) &&
          params[:iet].hour == 0 &&
          params[:iet].minute == 0 &&
          params[:iet].second == 0

    rescue ArgumentError => e
      ExceptionLogger.debug("exception: ArgumentError, message: preprocess_date_params, params: #{params[:ebt]},#{params[:iet]}")

      #TODO raise appropriate expception to be caught and handled elsewhere
    end
  end

  def record_api_event
    return unless request.headers['HTTP_AUTH_MODE'] == 'api'
    if @metadata.present? && @metadata.total_count.present?
      count_string = "total_count=#{@metadata.total_count}"
      response.headers['Location'] = request.url

      if response.headers['Location'].include?('?')
        response.headers['Location'] += '&'
      else
        response.headers['Location'] += '?'
      end

      response.headers['Location'] += count_string
    end

    res = self.instance_variables.select do |s|
      !s.to_s.include?('@_') &&
      !s.to_s.include?('chain') &&
      !s.to_s.include?('marked_for_same') &&
      !s.to_s.include?('current_') &&
      !s.to_s.include?('metadata')
    end.try(:first)

    res = self.instance_variable_get(res) if res.present?

    count = res.try(:count) || 1

    l = Logging::ApiLog.new(
        uri: request.env['REQUEST_URI'],
        controller: request.env["action_controller.instance"].class.to_s,
        action: request.env["action_controller.instance"].action_name,
        user: Thread.current[:current_user],
        query_source_entity: params[:query_source_entity]
    )
    l.count = count if count.present?
    l.save
  end

  def replicate(repl_type,object,params={})
    Thread.new do
      begin
        DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
        replications = Replication.where(repl_type: repl_type)
        repl_params = params.merge(cybox_object_id: object.cybox_object_id,
                                   guid: object.guid)
        replications.each do |replication|
          replication.send_data(repl_params.to_json,{"Content-type"=>'application/json'})
        end
      rescue Exception => e
        DatabasePoolLogging.log_thread_error(e, self.class.to_s, __LINE__)
      ensure
        unless Setting.DATABASE_POOL_ENSURE_THREAD_CONNECTION_CLEARING == false
          begin
            ActiveRecord::Base.clear_active_connections!
          rescue Exception => e
            DatabasePoolLogging.log_thread_error(e, self.class.to_s,
                                                 __LINE__)
          end
        end
      end
      DatabasePoolLogging.log_thread_exit(self.class.to_s, __LINE__)
    end 
  end
  
  # Sets initial request time
  def set_request_start_time
    @request_start_time = Time.now
  end
  
  # Sets end request time and logs according to request threshold
  def set_request_end_time
    @request_end_time = Time.now
    diff = @request_end_time - @request_start_time
    request_threshold = Rails.application.config.request_elapsed_time_threshold
    if !request_threshold.blank? && diff > request_threshold
      RequestLogger.warn("Application process elapsed time of #{diff} seconds for Request User: #{Thread.current[:current_user].username}, URL: #{request.url}")
    end
  end

  def update_and_log_pool_stats
    return unless Setting.DATABASE_POOL_LOGGING_ENABLED
    max_stale_seconds = Setting.DATABASE_POOL_STATS_UPDATE_FREQUENCY || 30
    DatabasePoolLogging.update_and_log_info(max_stale_seconds)
  end

  def sources_params
      return unless params[:contributing_sources_attributes].present? 
      params[:contributing_sources_attributes].each_with_index do |o,i|        
        if params[:contributing_sources_attributes][i][:organization_names].is_a?(Array)
          params[:contributing_sources_attributes][i][:organization_names] = params[:contributing_sources_attributes][i][:organization_names].join('|')
        end
        if params[:contributing_sources_attributes][i][:organization_info].is_a?(Array)
          params[:contributing_sources_attributes][i][:organization_info] = params[:contributing_sources_attributes][i][:organization_info].join('|')
        end        
        if params[:contributing_sources_attributes][i][:countries].is_a?(Array)
          params[:contributing_sources_attributes][i][:countries] = params[:contributing_sources_attributes][i][:countries].join('|')
        end
        if params[:contributing_sources_attributes][i][:administrative_areas].is_a?(Array)
          params[:contributing_sources_attributes][i][:administrative_areas] = params[:contributing_sources_attributes][i][:administrative_areas].join('|')
        end                
      end
  end
  def isa_params
    return unless params[:stix_markings_attributes].present?

    sma = params[:stix_markings_attributes].compact
    sma.each_with_index do |o,i|
      next unless sma[i][:isa_assertion_structure_attributes].present?
      if sma[i][:isa_assertion_structure_attributes][:cs_countries].is_a?(Array)
        sma[i][:isa_assertion_structure_attributes][:cs_countries] = sma[i][:isa_assertion_structure_attributes][:cs_countries].join(",")
      end
      if sma[i][:isa_assertion_structure_attributes][:cs_formal_determination].is_a?(Array)
        sma[i][:isa_assertion_structure_attributes][:cs_formal_determination] = sma[i][:isa_assertion_structure_attributes][:cs_formal_determination].join(",")
      end
      if sma[i][:isa_assertion_structure_attributes][:cs_orgs].is_a?(Array)
        sma[i][:isa_assertion_structure_attributes][:cs_orgs] = sma[i][:isa_assertion_structure_attributes][:cs_orgs].join(",")
      end
      if sma[i][:isa_assertion_structure_attributes][:cs_entity].is_a?(Array)
        sma[i][:isa_assertion_structure_attributes][:cs_entity] = sma[i][:isa_assertion_structure_attributes][:cs_entity].join(",")
      end
      if sma[i][:isa_assertion_structure_attributes][:cs_shargrp].is_a?(Array)
        sma[i][:isa_assertion_structure_attributes][:cs_shargrp] = sma[i][:isa_assertion_structure_attributes][:cs_shargrp].join(",")
      end
      if sma[i][:isa_assertion_structure_attributes][:cs_cui].is_a?(Array)
        sma[i][:isa_assertion_structure_attributes][:cs_cui] = sma[i][:isa_assertion_structure_attributes][:cs_cui].join(",")
      end
      if sma[i][:isa_assertion_structure_attributes][:cs_classification].is_a?(Array)
        sma[i][:isa_assertion_structure_attributes][:cs_classification] = sma[i][:isa_assertion_structure_attributes][:cs_classification].join(",")
      end
    end
  end

  protected

  STIX_MARKING_PERMITTED_PARAMS = {
      :stix_markings_attributes => [
          :id,
          :controlled_structure,
          :remote_object_type,
          :remote_object_field,
          :_destroy,
          :tlp_marking_structure_attributes => [
              :id,
              :color,
              :_destroy
          ],
          :isa_assertion_structure_attributes => [
              :id,
              :public_release,
              :cs_countries,
              :cs_orgs,
              :cs_entity,
              :cs_cui,
              :cs_shargrp,
              :re_custodian,
              :re_originator,
              :cs_formal_determination,
              :public_released_by,
              :public_released_on,
              :re_data_item_created_at,
              :cs_classification,
              :classified_by,
              :classified_on,
              :classification_reason,
              :privilege_default,
              :_destroy,
              :isa_privs_attributes => [
                  :id,
                  :action,
                  :effect,
                  :scope_countries,
                  :scope_entity,
                  :scope_is_all,
                  :scope_orgs,
                  :scope_shargrp
              ],
              :further_sharings_attributes => [:scope,:effect,:id,:_destroy]
          ],
          :isa_marking_structure_attributes => [
              :id,
              :data_item_created_at,
              :re_custodian,
              :re_originator
          ],
          :ais_consent_marking_structure_attributes => [
              :id, 
              :color,
              :consent,
              :proprietary,
              :_destroy
          ]
      ]
  }

  GFI_ATTRIBUTES = [
      :gfi_source_name,
      :gfi_action_name,
      :gfi_action_name_class,
      :gfi_action_name_subclass,
      :gfi_ps_regex,
      :gfi_ps_regex_class,
      :gfi_ps_regex_subclass,
      :gfi_cs_regex,
      :gfi_cs_regex_class,
      :gfi_cs_regex_subclass,
      :gfi_exp_sig_loc,
      :gfi_exp_sig_loc_class,
      :gfi_exp_sig_loc_subclass,
      :gfi_bluesmoke_id,
      :gfi_uscert_sid,
      :gfi_notes,
      :gfi_notes_class,
      :gfi_notes_subclass,
      :gfi_status,
      :gfi_uscert_doc,
      :gfi_uscert_doc_class,
      :gfi_uscert_doc_subclass,
      :gfi_special_inst,
      :gfi_special_inst_class,
      :gfi_special_inst_subclass,
      :gfi_type,
      :guid,
      :remote_object_type,
      :remote_object_id,
      :id
  ]
end
