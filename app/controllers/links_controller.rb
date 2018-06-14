class LinksController < ApplicationController
  include StixMarkingHelper
  
  def index
    @links = Link.where(:cybox_object_id => params[:ids]) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0
    marking_search_params = nil
    if params[:marking_search_params].present?
      marking_search_params = JSON.parse params[:marking_search_params]
    end

    if params[:q].present? || params[:column].present? && params[:column] == "cybox_uris.uri_normalized"
      solr_offset = offset
      solr_limit = limit
      
      # If performing a SOLR based search AND a Stix Marking search we need to do a two-step query
      # First, we perform the SOLR based query and grab the ids of the first 1000 results.
      # We use those IDs to limit the SQL query that will feed the Stix Marking search
      if marking_search_params.present?
        solr_offset = 0
        solr_limit = 1000
      end
      search = Search.link_search(params[:q], {
        column: params[:column] == "cybox_uris.uri_normalized" ? "uri" : params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        classification_limit: params[:classification_limit],
        offset: solr_offset
      })

      if marking_search_params.present?
        @links ||= Link.all.reorder(created_at: :desc)
        @links = @links.where(id: search.results.collect {|lnk| lnk.id})
      else
        total_count = search.total
        @links = search.results
      end

      @links ||= []
    else
      @links ||= Link.all.includes(:uri).reorder(created_at: :desc)

      @links = @links.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @links= @links.where("cybox_uris.uri_normalized=?",params[:uri_normalized]) if params[:uri_normalized].present?
      @links = @links.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])

      @links= apply_sort(@links, params)
    end

    if marking_search_params.present?
      @links = @links.joins(:stix_markings)
      @links = add_stix_markings_constraints(@links, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @links.count
      @links = @links.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count

    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, links: @links}}
      format.csv { render "links/index.csv.erb" }
    end
  end

  def show
    @link = Link.includes(
        audits: :user,
        indicators: :confidences
    ).find_by_cybox_object_id(params[:id]) ||
    Link.includes(
      audits: :user,
      indicators: :confidences).find_by_cybox_hash(params[:id])
    if @link
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Link.apply_default_policy_if_needed(@link)
      @link.reload

      render json: @link
    else
      render json: {errors: ["Invalid link record number"]}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create link observables"]}, status: 403
      return
    end
    @link = Link.find_or_create_by(link_params)
    if @link.valid?
      render(json: @link)
      return
    else
      render json: {errors: @link.errors}, status: :unprocessable_entity
    end
  end

  def update
    @link = Link.find_by_cybox_object_id(params[:id])

    unless Permissions.can_be_modified_by(current_user, @link)
      render json: {errors: ["You do not have the ability to modify this link observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @link = Link.find_or_update_by(@link, link_params)

    if @link.errors.blank?
      render(json: @link)
      return
    else
      render json: {errors: @link.errors}, status: :unprocessable_entity
    end
  end

private

  def link_params
    params.permit(:label,
                  :label_condition,
                  :guid,
                  :cybox_object_id,
                  STIX_MARKING_PERMITTED_PARAMS,
                  :uri_attributes=>[:uri_input, :uri_condition]
                  )
  end


end
