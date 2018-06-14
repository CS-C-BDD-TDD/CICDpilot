class UrisController < ApplicationController
  include StixMarkingHelper
  
  def index
    @uris = Uri.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.uri_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        classification_limit: params[:classification_limit],
        offset: solr_offset
      })

      if marking_search_params.present?
        @uris ||= Uri.all.reorder(created_at: :desc)
        @uris = @uris.where(id: search.results.collect {|uri| uri.id})
      else
        total_count = search.total
        @uris = search.results
      end

      @uris ||= []
    else
      @uris ||= Uri.all.reorder(created_at: :desc)

      @uris = @uris.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @uris = @uris.where(uri_normalized: params[:uri_in]) if params[:uri_in].present?
      @uris = @uris.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])

      @uris = apply_sort(@uris, params)
      @uris = @uris.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
      @uris = @uris.classification_greater(params[:classification_greater]) if params[:classification_greater] && Classification::CLASSIFICATIONS.include?(params[:classification_greater])
    end

    if marking_search_params.present?
      @uris = @uris.joins(:stix_markings)
      @uris = add_stix_markings_constraints(@uris, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @uris.count
      @uris = @uris.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, uris: @uris} }
      format.csv { render "uris/index.csv.erb" }
    end
  end

  def show
    @uri= Uri.includes(
        audits: :user,
        indicators: :confidences
    ).find_by_cybox_object_id(params[:id]) ||
    Uri.includes(
      audits: :user,
      indicators: :confidences).find_by_cybox_hash(params[:id])
    if @uri
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Uri.apply_default_policy_if_needed(@uri)
      @uri.reload

      render json: @uri
    else
      render json: {errors: ["Invalid uri record number"]}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create URI observables"]}, status: 403
      return
    end
    @uri = Uri.create(uri_params)
    if @uri.valid?
      render json: @uri
      return
    else
      render json: {errors: @uri.errors}, status: :unprocessable_entity
    end
  end

  def update
    @uri = Uri.find_by_cybox_object_id(params[:id])

    unless Permissions.can_be_modified_by(current_user, @uri)
      render json: {errors: ["You do not have the ability to modify this uri observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @uri.update(uri_params)

    if @uri.errors.blank?
      render json: @uri
      return
    else
      render json: {errors: @uri.errors}, status: :unprocessable_entity
    end
  end

private

  def uri_params
    params.permit(:uri_input,
                  :guid,
                  :uri_condition,
                  STIX_MARKING_PERMITTED_PARAMS,
                  :cybox_object_id
                  )
  end

end
