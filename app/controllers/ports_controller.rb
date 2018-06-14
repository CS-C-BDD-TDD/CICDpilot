class PortsController < ApplicationController
  include StixMarkingHelper
  
  def index
    @ports = Port.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.port_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset,
        classification_limit: params[:classification_limit]
      })

      if marking_search_params.present?
        @ports ||= Port.all.reorder(created_at: :desc)
        @ports = @ports.where(id: search.results.collect {|port| port.id})
      else
        total_count = search.total
        @ports = search.results
      end

      @ports ||= []
    else
      @ports ||= Port.all.reorder(created_at: :desc)

      @ports = @ports.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @ports = @ports.where(port: params[:port]) if params[:port].present?
      @ports = @ports.where(layer4_protocol: params[:layer4_protocol]) if params[:layer4_protocol].present?
      @ports = apply_sort(@ports, params)
      @ports = @ports.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
    end

    if marking_search_params.present?
      @ports = @ports.joins(:stix_markings)
      @ports = add_stix_markings_constraints(@ports, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @ports.count
      @ports = @ports.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, ports: @ports}}
      format.csv {render "ports/index.csv.erb"}
    end

  end

  def show
    @port = Port.includes(
        audits: :user,
        indicators: :confidences
    )
    @port = @port.find_by_cybox_object_id(params[:id]) || @port.find_by_cybox_hash(params[:id])
    if @port
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Port.apply_default_policy_if_needed(@port)
      @port.reload

      render json: @port
    else
      render json: {errors: "Invalid port record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create port observables"]}, status: 403
      return
    end
    @port = Port.create(port_params)
    if @port.errors.blank?
      render(json: @port)
      return
    else
      render json: {errors: @port.errors}, status: :unprocessable_entity
    end
  end

  def update
    @port = Port.find_by_cybox_object_id(params[:id])

    unless Permissions.can_be_modified_by(current_user,@port)
      render json: {errors: ["You do not have the ability to modify this port observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @port.update(port_params)

    if @port.errors.blank?
      render(json: @port)
      return
    else
      render json: {errors: @port.errors}, status: :unprocessable_entity
    end
  end

private

  def port_params
      params.permit(:port,
                    :layer4_protocol,
                    :guid,
                    :cybox_object_id,
                    STIX_MARKING_PERMITTED_PARAMS
                    )
  end

end
