class DnsQueriesController < ApplicationController
  include StixMarkingHelper
  
  def index
    @dns_queries = DnsQuery.where(:cybox_object_id => params[:ids]) if params[:ids]
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
      search = Search.dns_query_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset,
        classification_limit: params[:classification_limit]
      })

      if marking_search_params.present?
        @dns_queries ||= DnsQuery.all.reorder(created_at: :desc)
        @dns_queries = @dns_queries.where(id: search.results.collect {|dq| dq.id})
      else
        total_count = search.total
        @dns_queries = search.results
      end

      @dns_queries ||= []
    else
      @dns_queries ||= DnsQuery.all.reorder(created_at: :desc)

      @dns_queries = @dns_queries.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @dns_queries = apply_sort(@dns_queries, params)
      @dns_queries = @dns_queries.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
    end

    if marking_search_params.present?
      @dns_queries = @dns_queries.joins(:stix_markings)
      @dns_queries = add_stix_markings_constraints(@dns_queries, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @dns_queries.count
      @dns_queries = @dns_queries.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, dns_queries: @dns_queries} }
      format.csv {render "dns_queries/index.csv.erb"}
    end

  end

  def show
    @dns_query = 
    DnsQuery.includes(
      :indicators,
      audits: :user,
      stix_markings: [:isa_marking_structure,:tlp_marking_structure,:simple_marking_structure,{isa_assertion_structure: [:isa_privs,:further_sharings]}]
    ).find_by_cybox_object_id(params[:id]) || 
    DnsQuery.includes(
      :indicators,
      audits: :user,
      stix_markings: [:isa_marking_structure,:tlp_marking_structure,:simple_marking_structure,{isa_assertion_structure: [:isa_privs,:further_sharings]}]
    ).find_by_cybox_hash(params[:id])

    if @dns_query
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      DnsQuery.apply_default_policy_if_needed(@dns_query)
      @dns_query.reload

      render json: @dns_query
    else
      render json: {errors: "Could not find DNS Query object"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create DNS Query observables"]}, status: 403
      return
    end
    
    @dns_query = DnsQuery.new(dns_query_params)

    validation_errors = {:base => []}

    begin
      if params[:resource_record_guids].present?
        @dns_query.resource_record_guids = params[:resource_record_guids]
      end

      if params[:question_guids].present?
        @dns_query.question_guids = params[:question_guids]
      end

      @dns_query.save!
    rescue Exception => e
      validation_errors[:base] << e.to_s
    end

    if @dns_query.errors.present?
      validation_errors[:base] << @dns_query.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @dns_query
    else
      render json: {errors: @dns_query.errors}, status: :unprocessable_entity
    end
  end

  def update
    @dns_query = DnsQuery.find_by_cybox_object_id(params[:id])

    unless Permissions.can_be_modified_by(current_user,@dns_query)
      render json: {errors: ["You do not have the ability to modify this DNS Query observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @dns_query.update(dns_query_params)

    if params[:resource_record_guids].present?
      @dns_query.resource_record_guids = params[:resource_record_guids]
    end

    if params[:question_guids].present?
      @dns_query.question_guids = params[:question_guids]
    end

    validation_errors = {:base => []}
    
    if @dns_query.errors.present?
      validation_errors[:base] << @dns_query.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @dns_query
    else
      render json: {errors: @dns_query.errors}, status: :unprocessable_entity
    end
  end

private

  def dns_query_params
    params.permit(
      :guid,
      :cybox_object_id,
      STIX_MARKING_PERMITTED_PARAMS,
      :question_guids => [],
      :resource_record_guids => []
    )
  end

end
