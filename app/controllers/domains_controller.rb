class DomainsController < ApplicationController
  include StixMarkingHelper
  
  def index
    @domains = Domain.where(:cybox_object_id => params[:ids]) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0
    marking_search_params = nil
    if params[:marking_search_params].present?
      marking_search_params = JSON.parse params[:marking_search_params]
    end

    if params[:q].present?
      solr_offset = offset
      solr_limit = limit
      
      # If performing a SOLR based search AND a Stix Marking search we need to do a two-step query
      # First, we perform the SOLR based query and grab the ids of the first 1000 results.
      # We use those IDs to limit the SQL query that will feed the Stix Marking search
      if marking_search_params.present?
        solr_offset = 0
        solr_limit = 1000
      end
      search = Search.domain_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset,
        weather_map_only: params[:weather_map_only],
        classification_limit: params[:classification_limit],
        mainsearch: params[:mainsearch]
      })

      if marking_search_params.present?
        @domains ||= Domain.all.reorder(created_at: :desc)
        @domains = @domains.where(id: search.results.collect {|dom| dom.id})
      else
        total_count = search.total
        @domains = search.results
      end

      @domains ||= []
    elsif params[:type_ahead].present?
      # If performing a SOLR based search AND a Stix Marking search we need to do a two-step query
      # First, we perform the SOLR based query and grab the ids of the first 1000 results.
      # We use those IDs to limit the SQL query that will feed the Stix Marking search
      if marking_search_params.present?
        offset = 0
        limit = 1000
      end
      search = Search.domain_type_ahead(params[:type_ahead], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (limit || Sunspot.config.pagination.default_per_page),
        offset: offset,
        weather_map_only: params[:weather_map_only],
        classification_limit: params[:classification_limit],
        mainsearch: params[:mainsearch]
      })
      
      if marking_search_params.present?
        @domains ||= Domain.all.reorder(created_at: :desc)
        @domains = @domains.where(id: search.results.collect {|dom| dom.id})
      else
        total_count = search.total
        @domains = search.results
      end

      @domains ||= []
    else
      @domains ||= Domain.all.reorder(created_at: :desc)

      @domains = @domains.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @domains = @domains.where(name_normalized: params[:name]) if params[:name].present?
      @domains = apply_sort(@domains, params)
      @domains = @domains.where.not(combined_score: nil) if params[:weather_map_only] && params[:weather_map_only].to_bool
      @domains = @domains.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
    end

    if marking_search_params.present?
      @domains = @domains.joins(:stix_markings)
      @domains = add_stix_markings_constraints(@domains, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @domains.count
      @domains = @domains.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) {render json: {metadata: @metadata, domains: @domains}}
      format.csv {render "domains/index.csv.erb"}
    end

  end

  def show
    @domain = Domain.includes(
        audits: :user,
        indicators: :confidences
    )
    @domain = @domain.find_by_cybox_object_id(params[:id]) || @domain.find_by_cybox_hash(params[:id])
    if @domain
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Domain.apply_default_policy_if_needed(@domain)
      @domain.reload

      render json: @domain
    else
      render json: {errors: "Invalid domain record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create domain observables"]}, status: 403
      return
    end
    @domain = Domain.create(domain_params)
    if @domain.valid?
      render(json: @domain)
      return
    else
      render json: {errors: @domain.errors}, status: :unprocessable_entity
    end
  end

  def update
    @domain = Domain.find_by_cybox_object_id(params[:id])

    unless Permissions.can_be_modified_by(current_user,@domain)
      render json: {errors: ["You do not have the ability to modify this http session observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @domain.update(domain_params)

    if @domain.errors.blank?
      render(json: @domain)
      return
    else
      render json: {errors: @domain.errors}, status: :unprocessable_entity
    end
  end

  def valid
    unless params[:domain]
      render json: {errors: "You must supply a domain name"}, status: 400
      return
    end

    render json: {domain: params[:domain], status: PublicSuffix.valid?(params[:domain]) ? :valid : :invalid}, status: :ok
  end

  def create_weather_map
    csv_data = request.body.read

    if params['async'] == 'true'
      WeatherMapLogger.info("[DomainController][create_weather_map] params['async'] == true")
      render text: "Processing request", status: 202
      Thread.new do
        begin
          DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
          WeatherMapLogger.info("[DomainController][create_weather_map] Spinning up new thread.")
          total_good,rejects,created_ids = Domain.create_weather_map_data(csv_data)
          WeatherMapLogger.info("[DomainController][create_weather_map] Created: total_good: #{total_good},rejects: #{rejects}")
          replications = Replication.where(repl_type:'weathermap')
          if replications.present? && created_ids.present?
            replication_status = replications.map do |replication|
              WeatherMapLogger.info("[DomainController][create_weather_map] Replicating: ID: #{replication.id} URL: #{replication.url}")
              replication.send_data csv_data,{'Content-type'=>'text/csv'}
            end
            replication_status = replication_status.all?
            WeatherMapLogger.info("[DomainController][create_weather_map] Replicated: replication_status: #{replication_status}")
            objects = Domain.where id: created_ids
            objects.update_all replicated: replication_status,replicated_at: Time.now
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
      return
    end

    total_good,rejects,created_ids = Domain.create_weather_map_data(csv_data)
    render text: "#{total_good}", status: 201
    WeatherMapLogger.debug("[DomainController][create_weather_map] completed.")

    replications = Replication.where(repl_type:'weathermap')
    if replications.present? && created_ids.present?
      replication_status = replications.map do |replication|
        WeatherMapLogger.info("[DomainController][create_weather_map] Replicating: ID: #{replication.id} URL: #{replication.url}")
        replication.send_data csv_data,{'Content-type' => 'text/csv'}
      end
      replication_status = replication_status.all?
      WeatherMapLogger.info("[DomainController][create_weather_map] Replicated: replication_status: #{replication_status}")
      objects = Domain.where id: created_ids
      objects.update_all replicated: replication_status,replicated_at: Time.now
    end
  end

private

  def domain_params
    if gfi_permitted?
      params.permit(:name_input,
                    :name_condition,
                    :guid,
                    :cybox_object_id,
                    :mainsearch,
                    STIX_MARKING_PERMITTED_PARAMS,
                    :gfi_attributes=>GFI_ATTRIBUTES
                    )
    else
      params.permit(:name_input,
                    :name_condition,
                    :guid,
                    :cybox_object_id,
                    STIX_MARKING_PERMITTED_PARAMS,
                    :mainsearch
                    )
    end
  end

end
