class NetworkConnectionsController < ApplicationController
  include StixMarkingHelper
  
  def index
    @network_connections = NetworkConnection.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.network_connection_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        classification_limit: params[:classification_limit],
        offset: solr_offset
      })

      if marking_search_params.present?
        @network_connections ||= NetworkConnection.all.reorder(created_at: :desc)
        @network_connections = @network_connections.where(id: search.results.collect {|nc| nc.id})
      else
        total_count = search.total
        @network_connections = search.results
      end

      @network_connections ||= []
    else
      @network_connections ||= NetworkConnection.all.reorder(created_at: :desc)

      @network_connections = @network_connections.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @network_connections = @network_connections.where(dest_socket_address: params[:dest_socket_address]) if params[:dest_socket_address].present?
      @network_connections = @network_connections.where(dest_socket_hostname: params[:dest_socket_hostname]) if params[:dest_socket_hostname].present?
      @network_connections = @network_connections.where(dest_socket_is_spoofed: params[:dest_socket_is_spoofed]) if params[:dest_socket_is_spoofed].present?
      @network_connections = @network_connections.where(dest_socket_port: params[:dest_socket_port]) if params[:dest_socket_port].present?
      @network_connections = @network_connections.where(source_socket_address: params[:source_socket_address]) if params[:source_socket_address].present?
      @network_connections = @network_connections.where(source_socket_hostname: params[:source_socket_hostname]) if params[:source_socket_hostname].present?
      @network_connections = @network_connections.where(source_socket_is_spoofed: params[:source_socket_is_spoofed]) if params[:source_socket_is_spoofed].present?
      @network_connections = @network_connections.where(source_socket_port: params[:source_socket_port]) if params[:source_socket_port].present?
      @network_connections = @network_connections.where(layer3_protocol: params[:layer3_protocol]) if params[:layer3_protocol].present?
      @network_connections = @network_connections.where(layer4_protocol: params[:layer4_protocol]) if params[:layer4_protocol].present?
      @network_connections = @network_connections.where(layer7_protocol: params[:layer7_protocol]) if params[:layer7_protocol].present?
      @network_connections = @network_connections.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])

      @network_connections = apply_sort(@network_connections, params)
    end

    if marking_search_params.present?
      @network_connections = @network_connections.joins(:stix_markings)
      @network_connections = add_stix_markings_constraints(@network_connections, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @network_connections.count
      @network_connections = @network_connections.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, network_connections: @network_connections} }
      format.csv { render "network_connections/index.csv.erb" }
    end
  end

  def show
    @network_connection = NetworkConnection.includes(
        audits: :user,
        indicators: :confidences
    ).find_by_cybox_object_id(params[:id]) || 
    NetworkConnection.includes(
      audits: :user,
      indicators: :confidences
    ).find_by_cybox_object_id(params[:id])
    if @network_connection
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      NetworkConnection.apply_default_policy_if_needed(@network_connection)
      @network_connection.reload

      render json: @network_connection
    else
      render json: {errors: "Invalid network connection record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create network connection observables"]}, status: 403
      return
    end
    @network_connection = NetworkConnection.create(network_connection_params)
    
    if @network_connection.errors.blank?
      render json: @network_connection
    else
      render json: {errors: @network_connection.errors}, status: :unprocessable_entity
    end
  end

  def update
    @network_connection = NetworkConnection.find_by_cybox_object_id(params[:cybox_object_id])
    @network_connection ||= NetworkConnection.find_by_cybox_object_id(params[:id]) if params[:id]

    if !Permissions.can_be_modified_by(current_user,@network_connection)
      render json: {errors: ["You do not have the ability to modify this network connection observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @network_connection.update(network_connection_params)
    if @network_connection.errors.blank?
      render json: @network_connection
    else
      render json: {errors: @network_connection.errors}, status: :unprocessable_entity
    end
  end

private

  def network_connection_params
    params.permit(:dest_socket_address,
                  :dest_socket_hostname,
                  :dest_socket_is_spoofed,
                  :dest_socket_port,
                  :source_socket_address,
                  :source_socket_hostname,
                  :source_socket_is_spoofed,
                  :source_socket_port,
                  :layer3_protocol,
                  :layer4_protocol,
                  :layer7_protocol,
                  :guid,
                  STIX_MARKING_PERMITTED_PARAMS,
                  :cybox_object_id,
                  :layer_seven_connection_guids => []
          )
  end
end
