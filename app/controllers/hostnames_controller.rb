class HostnamesController < ApplicationController
  include StixMarkingHelper

  def index
    @hostnames = Hostname.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.hostname_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset,
        classification_limit: params[:classification_limit]
      })

      if marking_search_params.present?
        @hostnames ||= Hostname.all.reorder(created_at: :desc)
        @hostnames = @hostnames.where(id: search.results.collect {|hst| hst.id})
      else
        total_count = search.total
        @hostnames = search.results
      end

      @hostnames ||= []
    else
      @hostnames ||= Hostname.all.reorder(created_at: :desc)

      @hostnames = @hostnames.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @hostnames = @hostnames.where(hostname_normalized: params[:hostname]) if params[:hostname].present?
      @hostnames = @hostnames.where(naming_system: params[:naming_system]) if params[:naming_system].present?
      @hostnames = apply_sort(@hostnames, params)
      @hostnames = @hostnames.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
    end

    if marking_search_params.present?
      @hostnames = @hostnames.joins(:stix_markings)
      @hostnames = add_stix_markings_constraints(@hostnames, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @hostnames.count
      @hostnames = @hostnames.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, hostnames: @hostnames}}
      format.csv {render "hostnames/index.csv.erb"}
    end

  end

  def show
    @hostname = Hostname.includes(
        audits: :user,
        indicators: :confidences
    )
    @hostname = @hostname.find_by_cybox_object_id(params[:id]) || @hostname.find_by_cybox_hash(params[:id])
    if @hostname
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Hostname.apply_default_policy_if_needed(@hostname)
      @hostname.reload

      render json: @hostname
    else
      render json: {errors: "Invalid hostname record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create hostname observables"]}, status: 403
      return
    end
    @hostname = Hostname.create(hostname_params)
    if @hostname.errors.blank?
      render(json: @hostname)
      return
    else
      render json: {errors: @hostname.errors}, status: :unprocessable_entity
    end
  end

  def update
    @hostname = Hostname.find_by_cybox_object_id(params[:id])

    unless Permissions.can_be_modified_by(current_user,@hostname)
      render json: {errors: ["You do not have the ability to modify this hostname observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @hostname.update(hostname_params)

    if @hostname.errors.blank?
      render(json: @hostname)
      return
    else
      render json: {errors: @hostname.errors}, status: :unprocessable_entity
    end
  end

private

  def hostname_params
      params.permit(:hostname_input,
                    :hostname_condition,
                    :naming_system,
                    :is_domain_name,
                    :guid,
                    :cybox_object_id,
                    STIX_MARKING_PERMITTED_PARAMS
                    )
  end

end
