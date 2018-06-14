class VulnerabilitiesController < ApplicationController
  include StixMarkingHelper

  before_filter :isa_params, only: [:create,:update]

  def index
    @vulnerabilities = Vulnerability.where(:guid => params[:id]) if params[:id]
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
      search = Search.vulnerability_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset
      })

      if marking_search_params.present?
        @vulnerabilities ||= Vulnerability.all.reorder(updated_at: :desc).includes(:created_by_user)
        @vulnerabilities = @vulnerabilities.where(id: search.results.collect {|vul| vul.id})
      else
        total_count = search.total
        @vulnerabilities = search.results
      end

      @vulnerabilities ||= []
    else
      @vulnerabilities ||= Vulnerability.all.reorder(updated_at: :desc).includes(:created_by_user)

      @vulnerabilities = @vulnerabilities.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @vulnerabilities = apply_sort(@vulnerabilities, params)
      @vulnerabilities = @vulnerabilities.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
      @vulnerabilities = @vulnerabilities.classification_greater(params[:classification_greater]) if params[:classification_greater] && Classification::CLASSIFICATIONS.include?(params[:classification_greater])
    end

    if marking_search_params.present?
      @vulnerabilities = @vulnerabilities.joins(:stix_markings)
      @vulnerabilities = add_stix_markings_constraints(@vulnerabilities, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @vulnerabilities.count
      @vulnerabilities = @vulnerabilities.limit(limit).offset(offset)
    end
    
    @metadata = Metadata.new
    @metadata.total_count = total_count

    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, vulnerabilities: @vulnerabilities} }
      format.csv {render "vulnerabilities/index.csv.erb"}
    end
  end

  def create
    if !User.has_permission(current_user, 'create_remove_vulernabilities')
      render json: {errors: ["You do not have the ability to create Vulnerabilities"]}, status: 403
      return
    end
    
    validation_errors = {:base => []}
    
    @vulnerability = Vulnerability.new(vulnerability_params)
    begin
      @vulnerability.save!
    rescue Exception => e
      validation_errors[:base] << e.to_s
    end

    if @vulnerability.errors.present?
      validation_errors[:base] << @vulnerability.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @vulnerability
    else
      render json: {errors: validation_errors}, status: 403
    end
  end

  def show
    @vulnerability = Vulnerability.includes(audits: :user, stix_markings: [:isa_marking_structure, :tlp_marking_structure, :simple_marking_structure, {isa_assertion_structure: [:isa_privs,:further_sharings]}]).find_by_guid(params[:id])
    
    if @vulnerability
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Vulnerability.apply_default_policy_if_needed(@vulnerability)
      @vulnerability.reload
    end

    render json: @vulnerability, locals: {associations: {exploit_targets: 'embedded'}}
  end

  def update
    if (!Permissions.can_be_modified_by(current_user, @vulnerability))
      render json: {errors: ["You do not have the ability to modify vulnerabilities"]}, status: 403
      return
    end

    @vulnerability = Vulnerability.find_by_guid(params[:id])

    @vulnerability.update(vulnerability_params)

    validation_errors = {:base => []}

    if @vulnerability.errors.present?
      validation_errors[:base] << @vulnerability.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @vulnerability
    else
      render json: {errors: validation_errors}, status: 403
    end
  end

  def destroy
    @vulnerability = Vulnerability.find_by_guid(params[:id])
    if !User.has_permission(current_user, 'create_remove_vulernabilities') || !Permissions.can_be_deleted_by(current_user, @vulnerability)
      render json: {errors: ["You do not have the ability to delete vulnerabilities"]}, status: 403
      return
    end
    if @vulnerability.destroy
      head 204
    else
      render json: {errors:{} },status: :unprocessable_entity
    end
  end

private

  def vulnerability_params

    params.permit(:title,
                  :description,
                  :cve_id,
                  :osvdb_id,
                  :guid,
                  STIX_MARKING_PERMITTED_PARAMS)
  end

end
