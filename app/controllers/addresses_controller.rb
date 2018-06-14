class AddressesController < ApplicationController
  include StixMarkingHelper
  
  def index
    @addresses = Address.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.address_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset,
        classification_limit: params[:classification_limit],
        weather_map_only: params[:weather_map_only],
        mainsearch: params[:mainsearch],
        category: params[:category]
      })

      if marking_search_params.present?
        @addresses ||= Address.all.reorder(created_at: :desc)
        @addresses = @addresses.where(id: search.results.collect {|addr| addr.id})
      else
        total_count = search.total
        @addresses = search.results
      end

      @addresses ||= []
    elsif params[:all].present? && params[:all] == "true"
      @addresses ||= Address.all.reorder(created_at: :desc)

      @addresses = @addresses.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @addresses = @addresses.where(address_value_normalized: params[:address]) if params[:address].present?
      @addresses = @addresses.where(category: params[:category].split(',')) if params[:category].present?
      @addresses = apply_sort(@addresses, params)
      @addresses = @addresses.where.not(combined_score: nil) if params[:weather_map_only] && params[:weather_map_only].to_bool
      @addresses = @addresses.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
    else
      @addresses ||= Address.all.reorder(created_at: :desc).ipv4_ipv6_addresses

      @addresses = @addresses.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @addresses = @addresses.where(address_value_normalized: params[:address]) if params[:address].present?
      @addresses = @addresses.where(category: params[:category].split(',')) if params[:category].present?
      @addresses = apply_sort(@addresses, params)
      @addresses = @addresses.where.not(combined_score: nil) if params[:weather_map_only] && params[:weather_map_only].to_bool
      @addresses = @addresses.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
    end

    if marking_search_params.present?
      @addresses = @addresses.joins(:stix_markings)
      @addresses = add_stix_markings_constraints(@addresses, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @addresses.count
      @addresses = @addresses.limit(limit).offset(offset)
    end

    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, addresses: @addresses} }
      format.csv {render "addresses/index.csv.erb"}
    end
  end

  def show
    @address = Address.includes(
        audits: :user,
        indicators: :confidences
    ).find_by_cybox_object_id(params[:id]) ||
        Address.includes(
            audits: :user,
            indicators: :confidences ).find_by_cybox_hash(params[:id]) ||
        Address.includes(
            audits: :user,
            indicators: :confidences ).find_by_address_value_normalized(URI.decode(params[:id])) ||
        Address.includes(
            audits: :user,
            indicators: :confidences ).find_by_address_input(params[:id])
    if @address
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Address.apply_default_policy_if_needed(@address)
      @address.reload

      render json: @address
    else
      render json: {errors: "Invalid address record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create address observables"]}, status: 403
      return
    end
    @address = Address.create(address_params)
    if @address.valid?
      render(json: @address)
      return
    else
      render json: {errors: @address.errors}, status: :unprocessable_entity
    end
  end

  def update
    @address = Address.find_by_cybox_object_id(params[:id])

    unless Permissions.can_be_modified_by(current_user,@address)
      render json: {errors: ["You do not have the ability to modify this Address observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @address.update(address_params)

    if @address.errors.blank?
      render(json: @address)
      return
    else
      render json: {errors: @address.errors}, status: :unprocessable_entity
    end
  end

  def create_weather_map
    csv_data = request.body.read

    if params['async'] == 'true'
      WeatherMapLogger.info("[AddressController][create_weather_map] params['async'] == true")
      render text: "Processing request", status: 202
      Thread.new do
        begin
          DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
          WeatherMapLogger.info("[AddressController][create_weather_map] Spinning up new thread.")
          total_good, rejects, created_ids = Address.create_weather_map_data(csv_data)
          WeatherMapLogger.info("[AddressController][create_weather_map] Created: total_good: #{total_good},rejects: #{rejects}")
          replications = Replication.where(repl_type: 'weathermap')
          if replications.present? && created_ids.present?
            replication_status = replications.map do |replication|
              WeatherMapLogger.info("[AddressController][create_weather_map] Replicating: ID: #{replication.id} URL: #{replication.url}")
              replication.send_data csv_data, {'Content-type' => 'text/csv'}
            end
            replication_status = replication_status.all?
            WeatherMapLogger.info("[AddressController][create_weather_map] Replicated: replication_status: #{replication_status}")
            objects = Address.where id: created_ids
            objects.update_all replicated: replication_status, replicated_at: Time.now
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

    total_good,rejects,created_ids = Address.create_weather_map_data(csv_data)
    render text: "#{total_good}", status: 201
    WeatherMapLogger.debug("[AddressController][create_weather_map] completed.")

    replications = Replication.where(repl_type:'weathermap')
    if replications.present? && created_ids.present?
      replication_status = replications.map do |replication|
        WeatherMapLogger.info("[AddressController][create_weather_map] Replicating: ID: #{replication.id} URL: #{replication.url}")
        replication.send_data csv_data,{'Content-type' => 'text/csv'}
      end
      replication_status = replication_status.all?
      WeatherMapLogger.info("[AddressController][create_weather_map] Replicated: replication_status: #{replication_status}")
      objects = Address.where id: created_ids
      objects.update_all replicated: replication_status,replicated_at: Time.now
    end
  end

private

  def address_params
    if gfi_permitted?
      params.permit(:address_input,
                    :guid,
                    :cybox_object_id,
                    :address_condition,
                    :mainsearch,
                    STIX_MARKING_PERMITTED_PARAMS,
                    :gfi_attributes=>GFI_ATTRIBUTES
                    )
    else
      params.permit(:address_input,
                    :guid,
                    :cybox_object_id,
                    :address_condition,
                    STIX_MARKING_PERMITTED_PARAMS,
                    :mainsearch
                    )
    end
  end

end
