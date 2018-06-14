class HttpSessionsController < ApplicationController
  include StixMarkingHelper
  
  def index
    @http_sessions = HttpSession.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.http_session_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        classification_limit: params[:classification_limit],
        offset: solr_offset
      })

      if marking_search_params.present?
        @http_sessions ||= HttpSession.all.reorder(created_at: :desc)
        @http_sessions = @http_sessions.where(id: search.results.collect {|hs| hs.id})
      else
        total_count = search.total
        @http_sessions = search.results
      end

      @http_sessions ||= []
    else
      @http_sessions ||= HttpSession.all.reorder(created_at: :desc)

      @http_sessions = @http_sessions.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @http_sessions = @http_sessions.where(user_agent: params[:user_agent]) if params[:user_agent]
      @http_sessions = @http_sessions.where(domain_name: params[:domain_name]) if params[:domain_name]
      @http_sessions = @http_sessions.where(referer: params[:referer]) if params[:referer]
      @http_sessions = @http_sessions.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])

      @http_sessions = apply_sort(@http_sessions, params)
    end

    if marking_search_params.present?
      @http_sessions = @http_sessions.joins(:stix_markings)
      @http_sessions = add_stix_markings_constraints(@http_sessions, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @http_sessions.count
      @http_sessions = @http_sessions.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, http_sessions: @http_sessions} }
      format.csv { render "http_sessions/index.csv.erb" }
    end
  end

  def show
    @http_session = HttpSession.includes(
        audits: :user,
        indicators: :confidences
    ).find_by_cybox_object_id(params[:id]) || 
    HttpSession.includes(
      audits: :user,
      indicators: :confidences).find_by_cybox_hash(params[:id])

    if @http_session
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      HttpSession.apply_default_policy_if_needed(@http_session)
      @http_session.reload

      render json: @http_session
    else
      render json: {errors: "Invalid http_session record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create http_session observables"]}, status: 403
      return
    end
    @http_session = HttpSession.create(http_session_params)
    validate(@http_session)
  end

  def update
    @http_session= HttpSession.find_by_cybox_object_id(params[:id])

    if !Permissions.can_be_modified_by(current_user,@http_session)
      render json: {errors: ["You do not have the ability to modify this http session observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @http_session.update(http_session_params)
    validate(@http_session)
   end

private
  def validate(object)
    if object.valid?
      render(json: object) && return
    else
      render json: {errors: object.errors}, status: :unprocessable_entity
    end
  end

  def http_session_params
    params.permit(:user_agent,
                  :user_agent_condition,
                  :guid,
                  :cybox_object_id,
                  :domain_name,
                  :port,
                  :referer,
                  STIX_MARKING_PERMITTED_PARAMS,
                  :pragma
                  )
  end

end
