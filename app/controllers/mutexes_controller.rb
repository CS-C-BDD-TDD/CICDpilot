class MutexesController < ApplicationController
  include StixMarkingHelper
  
  def index
    @mutexes = CyboxMutex.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.mutex_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        classification_limit: params[:classification_limit],
        offset: solr_offset
      })

      if marking_search_params.present?
        @mutexes ||= CyboxMutex.all.reorder(created_at: :desc)
        @mutexes = @mutexes.where(id: search.results.collect {|mtx| mtx.id})
      else
        total_count = search.total
        @mutexes = search.results
      end

      @mutexes ||= []
    else
      @mutexes ||= CyboxMutex.all.reorder(created_at: :desc)

      @mutexes = @mutexes.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @mutexes = @mutexes.where(name: params[:name]) if params[:name].present?
      @mutexes = @mutexes.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])

      @mutexes = apply_sort(@mutexes, params)
    end

    if marking_search_params.present?
      @mutexes = @mutexes.joins(:stix_markings)
      @mutexes = add_stix_markings_constraints(@mutexes, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @mutexes.count
      @mutexes = @mutexes.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, mutexes: @mutexes} }
      format.csv { render "mutexes/index.csv.erb" }
    end
  end

  def show
    @mutex = CyboxMutex.includes(
        audits: :user,
        indicators: :confidences
    ).find_by_cybox_object_id(params[:id]) ||
    CyboxMutex.includes(
      audits: :user,
      indicators: :confidences
    ).find_by_cybox_hash(params[:id])
    if @mutex
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      CyboxMutex.apply_default_policy_if_needed(@mutex)
      @mutex.reload

      render json: @mutex
    else
      render json: {errors: "Invalid mutex record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create mutex observables"]}, status: 403
      return
    end
    @mutex = CyboxMutex.create(mutex_params)
    if @mutex.valid?
      render(json: @mutex) 
      return
    else
      render json: {errors: @mutex.errors}, status: :unprocessable_entity
    end
  end

  def update
    @mutex = CyboxMutex.find_by_cybox_object_id(params[:id])

    unless Permissions.can_be_modified_by(current_user, @mutex)
      render json: {errors: ["You do not have the ability to modify this mutex observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @mutex.update(mutex_params)

    if @mutex.errors.blank?
      render(json: @mutex)
      return
    else
      render json: {errors: @mutex.errors}, status: :unprocessable_entity
    end
  end

private

  def mutex_params
    params.permit(:name,
                  :guid,
                  :name_condition,
                  STIX_MARKING_PERMITTED_PARAMS,
                  :cybox_object_id
                  )
  end

end
