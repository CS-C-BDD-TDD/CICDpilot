class RegistriesController < ApplicationController
  include StixMarkingHelper
  
  def index
    @registries = Registry.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.registry_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        classification_limit: params[:classification_limit],
        offset: solr_offset
      })

      if marking_search_params.present?
        @registries ||= Registry.all.reorder(created_at: :desc)
        @registries = @registries.where(id: search.results.collect {|reg| reg.id})
      else
        total_count = search.total
        @registries = search.results
      end

      @registries ||= []
    else
      @registries ||= Registry.all.reorder(created_at: :desc)

      @registries = @registries.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @registries = @registries.where(hive: params[:hive]) if params[:hive].present?
      @registries = @registries.where(key: params[:key]) if params[:key].present?
      @registries = @registries.where(reg_name: params[:reg_name]) if params[:reg_name].present?
      @registries = @registries.where(reg_value: params[:reg_value]) if params[:reg_value].present?
      @registries = @registries.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])

      @registries = apply_sort(@registries, params)
    end

    if marking_search_params.present?
      @registries = @registries.joins(:stix_markings)
      @registries = add_stix_markings_constraints(@registries, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @registries.count
      @registries = @registries.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format| 
      format.any(:json, :html) { render json: {metadata: @metadata, registries: @registries} }
      format.csv { render "registries/index.csv.erb" }
    end
  end

  def show
    @registry = Registry.includes(
        audits: :user,
        indicators: :confidences
    ).find_by_cybox_object_id(params[:id]) ||
    Registry.includes(
      audits: :user,
      indicators: :confidences).find_by_cybox_hash(params[:id])
    if @registry
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Registry.apply_default_policy_if_needed(@registry)
      @registry.reload

      render json: @registry
    else
      render json: {errors: "Invalid registry record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create registry observables"]}, status: 403
      return
    end
    @registry = Registry.special_create_or_update(nil, registry_params)
    if @registry.errors.blank? && @registry.valid?
      render(json: @registry) 
      return
    else
      render json: {errors: @registry.errors}, status: :unprocessable_entity
    end
  end

  def update
    @registry = Registry.find_by_cybox_object_id(params[:id])

    unless Permissions.can_be_modified_by(current_user, @registry)
      render json: {errors: ["You do not have the ability to modify this registry observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @registry = Registry.special_create_or_update(@registry, registry_params)

    if @registry.errors.blank?
      render(json: @registry)
      return
    else
      render json: {errors: @registry.errors}, status: :unprocessable_entity
    end
  end

private

  def registry_params
    params.permit(
                   :hive,
                   :hive_condition,
                   :key,
                   :guid,
                   :cybox_object_id,
                   STIX_MARKING_PERMITTED_PARAMS,
                   :registry_values_attributes=>[:reg_name,:reg_value, :data_condition, :reg_value_id]
                 )
  end

end
