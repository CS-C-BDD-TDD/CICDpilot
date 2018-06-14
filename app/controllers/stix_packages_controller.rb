class StixPackagesController < ApplicationController
  include StixMarkingHelper
  
  before_filter :isa_params, :sources_params, only: [:create,:update]

  def create
    if !User.has_permission(current_user, 'create_package_report')
      render json: {errors: ["You do not have the ability to create packages"]}, status: 403
      return
    end

    if params[:acs_set_id].present?
      unless AcsSet.for_org(User.current_user.organization).collect(&:guid).include?(params[:acs_set_id])
        render json: {errors: ["You do not have the ability to associate this object with this ACS Set"]}, status: 403
        return
      end
    end
    @stix_package = StixPackage.new(stix_package_params)

    validation_errors = {:base => []}

    begin
      @stix_package.save!
    rescue Exception => e
      validation_errors[:base] << e.to_s
    end

    # Look through all the indicators_packages and find errors. Add them to the errors array.
    @stix_package.indicators_packages.each do |ip|
      if ip.errors.messages.present? && ip.errors.messages[:base].present?
        ip.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # if validate comes back with errors
    if validation_errors[:base].present?
      render json: {errors: validation_errors}, status: 403
      return
    else
      render json: @stix_package
    end
  end

  def show
    @stix_package = StixPackage.find_by_stix_id(params[:id])
    
    # We don't create the default markings on ingest anymore for performance
    # reasons, so create them now, if needed
    StixPackage.apply_default_policy_if_needed(@stix_package)
    @stix_package.reload
    
    render json: @stix_package, locals: {associations: {observables: 'embedded'}}
  end

  def download
    @package = StixPackage.find_by_stix_id(params[:stix_package_id])
    
    # We don't create the default markings on ingest anymore for performance
    # reasons, so create them now, if needed
    # We need to collect all child objects that will need markings as well
    isa_check = []
    isa_check << @package
    @package.indicators.each {|ind|
      isa_check << ind
      
      ind.observables.each {|obsv|
        if obsv.object.class.respond_to?(:apply_default_policy_if_needed)
          isa_check << obsv.object
        end
      }
    }
    
    isa_check.each {|x| x.class.apply_default_policy_if_needed(x)}
    @package.reload

    stream = render_to_string(template: "stix_packages/show")
    send_data(stream, type: "text/xml", filename: "#{@package.stix_id}.xml")

    Thread.new do
      begin
        DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
        @package.indicators.each do |indicator|
          audit = Audit.basic
          audit.item = indicator
          audit.audit_type = :stix_download
          audit.message = "Indicator Downloaded as STIX"
          audit.user = current_user
          indicator.audits << audit
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

  def download_ais
    @package = StixPackage.find_by_stix_id(params[:stix_package_id])
    
    # We don't create the default markings on ingest anymore for performance
    # reasons, so create them now, if needed
    # We need to collect all child objects that will need markings as well
    isa_check = []
    isa_check << @package
    @package.indicators.each {|ind|
      isa_check << ind
      
      ind.observables.each {|obsv|
        if obsv.object.class.respond_to?(:apply_default_policy_if_needed)
          isa_check << obsv.object
        end
      }
    }
    
    isa_check.each {|x| x.class.apply_default_policy_if_needed(x)}
    @package.reload

    stream = render_to_string(template: "stix_packages/show_ais")
    send_data(stream, type: "text/xml", filename: "#{@package.stix_id}.xml")

    Thread.new do
      begin
        DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
        @package.indicators.each do |indicator|
          audit = Audit.basic
          audit.item = indicator
          audit.audit_type = :ais_download
          audit.message = "Indicator Downloaded as AIS"
          audit.user = current_user
          indicator.audits << audit
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

  def index
    @stix_packages = StixPackage.where(:stix_id => params[:ids]) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0
    marking_search_params = nil
    if params[:marking_search_params].present?
      marking_search_params = JSON.parse params[:marking_search_params]
    end
    
    params[:created_ebt] = params[:created_ebt].to_date.beginning_of_day if params[:created_ebt].present?
    params[:created_iet] = params[:created_iet].to_date.end_of_day if params[:created_iet].present?
    params[:updated_ebt] = params[:updated_ebt].to_date.beginning_of_day if params[:updated_ebt].present?
    params[:updated_iet] = params[:updated_iet].to_date.end_of_day if params[:updated_iet].present?

    if params[:q].present? || params[:title_q].present? || params[:short_desc_q].present? || 
       params[:created_by_q].present? || params[:updated_by_q].present?
      solr_offset = offset
      solr_limit = limit
      
      # If performing a SOLR based search AND a Stix Marking search we need to do a two-step query
      # First, we perform the SOLR based query and grab the ids of the first 1000 results.
      # We use those IDs to limit the SQL query that will feed the Stix Marking search
      if marking_search_params.present?
        solr_offset = 0
        solr_limit = 1000
      end
      search = Search.package_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        created_ebt: params[:created_ebt],
        created_iet: params[:created_iet],
        updated_ebt: params[:updated_ebt],
        updated_iet: params[:updated_iet], 
        title_q: params[:title_q], 
        created_by_q: params[:created_by_q],
        updated_by_q: params[:updated_by_q], 
        short_desc_q: params[:short_desc_q],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset,
        mainsearch: params[:mainsearch]
      })
      
      if marking_search_params.present?
        @stix_packages ||= StixPackage.all.reorder(updated_at: :desc)
        @stix_packages = @stix_packages.where(id: search.results.collect {|pkg| pkg.id})
      else
        total_count = search.total
        @stix_packages = search.results
      end

      @stix_packages ||= []
    else
      @stix_packages ||= StixPackage.all.reorder(updated_at: :desc)

      @stix_packages = @stix_packages.where(created_at: params[:created_ebt]..params[:created_iet]) if params[:created_ebt].present? && params[:created_iet].present?
      @stix_packages = @stix_packages.where(updated_at: params[:updated_ebt]..params[:updated_iet]) if params[:updated_ebt].present? && params[:updated_iet].present?
      @stix_packages = @stix_packages.where(title: params[:title]) if params[:title].present?
      @stix_packages = @stix_packages.where(short_description: params[:short_description]) if params[:short_description].present?
      @stix_packages = @stix_packages.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
      @stix_packages = @stix_packages.classification_greater(params[:classification_greater]) if params[:classification_greater] && Classification::CLASSIFICATIONS.include?(params[:classification_greater])
      @stix_packages = apply_sort(@stix_packages, params)
    end
    
    if marking_search_params.present?
      # We need to search markings both that are attached to this object or that may be
      # available through an AcsSet. Since Rails doesn't support Unions, we need to make it
      # it through straight sql
      
      # We need to limit the columns being queried to eliminate CLOB columns. Oracle doesn't like
      # CLOB columns in a FROM clause. Limit to only the columns in the grid or required by the query
      # Remove any existing ordering as it will create invalid SQL
      from_query = @stix_packages.reorder('').select("stix_packages.id as id, " +
          "stix_packages.stix_id as stix_id, stix_packages.guid as guid, " +
             "stix_packages.acs_set_id as acs_set_id, stix_packages.title as title, " +
             "stix_packages.short_description_normalized as short_description_normalized, " +
             "stix_packages.username as username, stix_packages.created_at as created_at, " +
             "stix_packages.updated_at as updated_at")
      
      scope_normal = from_query.joins(:stix_markings)
      scope_normal = add_stix_markings_constraints(scope_normal, marking_search_params)
      
      scope_acs = from_query.joins(:acs_set).joins("JOIN stix_markings ON stix_markings.remote_object_id = acs_sets.guid and stix_markings.remote_object_type = 'AcsSet'")
      scope_acs = add_stix_markings_constraints(scope_acs, marking_search_params)
      
      order = sanitize_sort_order(StixPackage.column_names, params[:column])
      direction = sanitize_sort_direction(params[:direction])
      
      partial_packages = StixPackage.from("(#{scope_normal.to_sql} UNION #{scope_acs.to_sql} ORDER BY #{order} #{direction}) stix_packages")

      total_count = partial_packages.count
      partial_packages = partial_packages.limit(limit).offset(offset)
              
      # Now requery to get the full objects
      @stix_packages = StixPackage.where(id: partial_packages.collect{|pkg| pkg.id})
      @stix_packages = apply_sort(@stix_packages, params)
    end
    
    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @stix_packages.count
      @stix_packages = @stix_packages.limit(limit).offset(offset)
    end
    
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, stix_packages: @stix_packages} }
      format.csv {render "stix_packages/index.csv.erb"}
    end
  end

  def update
    @stix_package = StixPackage.find_by_stix_id(params[:id])

    if (!Permissions.can_be_modified_by(current_user, @stix_package))
      render json: {errors: ["You do not have the ability to modify packages"]}, status: 403
      return
    end

    if params[:acs_set_id].present?
      unless AcsSet.for_org(User.current_user.organization).collect(&:guid).include?(params[:acs_set_id])
        render json: {errors: ["You do not have the ability to associate this object with this ACS Set"]}, status: 403
        return
      end
    end

    Audit.justification = params[:justification] if params[:justification]
    @stix_package.update(stix_package_params)

    validation_errors = {:base => []}

    if @stix_package.errors.present?
      validation_errors[:base] << @stix_package.errors.full_messages
    end

    # Look through all the indicators_packages and find errors. Add them to the errors array.
    @stix_package.indicators_packages.each do |ip|
      if ip.errors.messages.present? && ip.errors.messages[:base].present?
        ip.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # if validate comes back with errors, we probably have a error in indicators_package
    if validation_errors[:base].present?
      render json: {errors: validation_errors}, status: 403
      return
    else
      render json: @stix_package
    end
  end

  def destroy
    @stix_package = StixPackage.find_by_stix_id(params[:id])
    if !Permissions.can_be_deleted_by(current_user, @stix_package)
      render json: {errors: ["You do not have the ability to delete packages"]}, status: 403
      return
    end
    if @stix_package.destroy
      head 204
    else
      render json: {errors:{} },status: :unprocessable_entity
    end
  end

  def bulk_inds
    # Make sure we only get the params that were expecting
    params.permit(:indicator_stix_ids, :package_stix_ids)

    # keep track of how many packages we have updated.
    amount_packages = 0

    # Create an array of validation errors.
    validation_errors = {errors: []}

    # For each package that we get we need to add the indicators to it if it doesnt exist.
    params[:package_stix_ids].each do |e|
      @package = StixPackage.find_by_stix_id(e)
      
      if (!Permissions.can_be_modified_by(current_user, @stix_package))
        validation_errors[:errors] << "You do not have the ability to modify packages"
        return
      end

      if params[:indicator_stix_ids].present?

        # subtract the params array of guids from the existing ones so we dont get dups.
        to_add_indicators = params[:indicator_stix_ids] - @package.indicator_ids

        # check if theirs anything new to add to the array of system tags
        if to_add_indicators.present?
          # wrap the add in a try catch block incase classification errors occur.
          begin
            to_add_indicators.each do |id_to_be_linked|
              obj = Indicator.find_by_stix_id(id_to_be_linked)
              if obj.present? && @package.portion_marking.present? && obj.portion_marking.present? && Classification::CLASSIFICATIONS.index(@package.portion_marking) < Classification::CLASSIFICATIONS.index(obj.portion_marking)
                render json: {errors: ["Invalid Classification, Classification of a selected Stix Package is less than the classification of the selected Indicator(s)"]}, status: 403
                return
              end
            end

            @package.indicator_stix_ids = @package.indicator_ids.concat(to_add_indicators)
            amount_packages += 1

            if !@package.valid?
              validation_errors[:errors] << @package.title + " : " + @package.errors.full_messages.first
            end
          rescue Exception => e
            validation_errors[:errors] << @package.title + " : " + e.to_s 
            next
          end
        else
          validation_errors[:errors] << @package.title + " : " + "No new Indicators to add."
        end
      else
        validation_errors[:errors] << @package.title + " : " + "No Indicators selected."
      end
    end

    # build the toastr message that will be rendered 
    success_string = "Successfully Added " + params[:indicator_stix_ids].count.to_s + " Indicators to " + amount_packages.to_s + "/" + params[:package_stix_ids].count.to_s + " Packages."

    render json: {base: success_string, errors: validation_errors[:errors]}
  end

  def coa_additions
    # Make sure we only get the params that were expecting
    params.permit(:stix_package_stix_id, :coa_stix_ids)

    @stix_package = StixPackage.find_by_stix_id(params[:stix_package_stix_id])

    if params[:coa_stix_ids].present?
      if !User.has_permission(current_user,'link_packages_to_course_of_actions')
        render json: {errors: ["You do not have the ability to link Stix Packages to Courses of Action"]}, status: 403
        return
      end

      # subtract the params array of stix_ids from the existing ones so we dont get dups.
      to_add_coas = params[:coa_stix_ids] - @stix_package.course_of_action_ids

      # check if theirs anything new to add to the array of Coa IDs
      if to_add_coas.present?
        to_add_coas.each do |id_to_be_linked|
          obj = CourseOfAction.find_by_stix_id(id_to_be_linked)
          if obj.present? && @stix_package.portion_marking.present? && obj.portion_marking.present? && Classification::CLASSIFICATIONS.index(@stix_package.portion_marking) < Classification::CLASSIFICATIONS.index(obj.portion_marking)
            render json: {errors: ["Invalid Classification, Classification of a selected Stix Package is less than the classification of the selected COA object(s)"]}, status: 403
            return
          end
        end

        @stix_package.course_of_action_stix_ids = @stix_package.course_of_action_ids.concat(to_add_coas);
      end
    end
    
    if @stix_package.save
      @stix_package.reload
      render json: @stix_package, locals: {associations: {observables: 'embedded'}}
    else
      render json: {errors: @stix_package.errors}, status: :unprocessable_entity
    end
  end

  def suggested_packages
    # only permit the indicator stix ids
    params.permit(:indicator_stix_ids, :limit)

    @stix_packages = []

    if params[:indicator_stix_ids].present?
      @stix_packages = Indicator.where(stix_id: params[:indicator_stix_ids]).joins(:stix_packages).collect(&:stix_packages).flatten.uniq
    end

    if params[:exploit_target_stix_ids].present?
      @stix_packages = ExploitTarget.where(stix_id: params[:exploit_target_stix_ids]).joins(:stix_packages).collect(&:stix_packages).flatten.uniq
    end

    @stix_packages = @stix_packages.select{|sp| Classification::CLASSIFICATIONS.index(sp.portion_marking) >= Classification::CLASSIFICATIONS.index(params[:limit])} if params[:limit] && Classification::CLASSIFICATIONS.include?(params[:limit])

    @metadata = Metadata.new
    @metadata.total_count = @stix_packages.count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, stix_packages: @stix_packages} }
    end
  end

=begin
  def upload
    raw_xml = request.body.read
    @stix_package = StixPackage.create_from_xml(raw_xml)
    if @stix_package.save
      render json: @stix_package, status: :created
    else
      render json: @stix_package.errors, status: :unprocessable_entity
    end
  end
=end

private

  def stix_package_params
    # Handle deep_munge and allow empty set
    params[:indicator_stix_ids] ||= []
    
    params[:course_of_action_stix_ids] ||= []

    params[:exploit_target_stix_ids] ||= []

    params[:ttp_stix_ids] ||= []


    if User.has_permission(current_user,'view_pii_fields')
      params.permit(:title,
                    :stix_id,
                    :description,
                    :short_description,
                    :short_description_normalized,
                    :acs_set_id,
                    :package_intent,
                    :mainsearch,
                    :submission_mechanism,
                    STIX_MARKING_PERMITTED_PARAMS,
                    :indicator_stix_ids => [],
                    :course_of_action_stix_ids => [],
                    :exploit_target_stix_ids => [],
                    :ttp_stix_ids => [],
                    :contributing_sources_attributes => [:organization_info,:is_federal, :guid, :id, :_destroy, :organization_names,:countries,:administrative_areas]
      )
    else
      params.permit(:title,
                    :stix_id,
                    :acs_set_id,
                    :submission_mechanism,
                    :package_intent,
                    :mainsearch,
                    STIX_MARKING_PERMITTED_PARAMS,
                    :indicator_stix_ids => [],
                    :course_of_action_stix_ids => [],
                    :exploit_target_stix_ids => [],
                    :ttp_stix_ids => [],
                    :contributing_sources_attributes => [:organization_info,:is_federal, :guid, :id, :_destroy, :organization_names,:countries,:administrative_areas]

      )
    end
  end

end
