class AttackPatternsController < ApplicationController
  include StixMarkingHelper

  def index
    @attack_patterns = AttackPattern.where(:stix_id => params[:ids]) if params[:ids]
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
      search = Search.attack_pattern_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset
      })
      
      if marking_search_params.present?
        @attack_patterns ||= AttackPattern.all.reorder(updated_at: :desc).includes(:created_by_user)
        @attack_patterns = @attack_patterns.where(id: search.results.collect {|att| att.id})
      else
        total_count = search.total
        @attack_patterns = search.results
      end

      @attack_patterns ||= []
    else
      @attack_patterns ||= AttackPattern.all.reorder(updated_at: :desc).includes(:created_by_user)

      @attack_patterns = @attack_patterns.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @attack_patterns = apply_sort(@attack_patterns, params)
      @attack_patterns = @attack_patterns.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
      @attack_patterns = @attack_patterns.classification_greater(params[:classification_greater]) if params[:classification_greater] && Classification::CLASSIFICATIONS.include?(params[:classification_greater])
    end

    if marking_search_params.present?
      @attack_patterns = @attack_patterns.joins(:stix_markings)
      @attack_patterns = add_stix_markings_constraints(@attack_patterns, marking_search_params)
    end
    
    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @attack_patterns.count
      @attack_patterns = @attack_patterns.limit(limit).offset(offset)
    end
    
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, attack_patterns: @attack_patterns} }
      format.csv {render "attack_patterns/index.csv.erb"}
    end
  end

  def create
    if !User.has_permission(current_user, 'create_remove_attack_patterns')
      render json: {errors: ["You do not have the ability to create Attack Patterns"]}, status: 403
      return
    end

    validation_errors = {:base => []}
    
    @attack_pattern = AttackPattern.new(attack_pattern_params)
    
    begin
      @attack_pattern.save!
    rescue Exception => e
      validation_errors[:base] << e.to_s
    end

    if @attack_pattern.errors.present?
      validation_errors[:base] << @attack_pattern.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @attack_pattern
    else
      render json: {errors: validation_errors}, status: 403
    end
  end

  def show
    @attack_pattern = AttackPattern.includes(audits: :user, stix_markings: [:isa_marking_structure, :tlp_marking_structure, :simple_marking_structure, {isa_assertion_structure: [:isa_privs,:further_sharings]}]).find_by_stix_id(params[:id])

    if @attack_pattern
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      AttackPattern.apply_default_policy_if_needed(@attack_pattern)
      @attack_pattern.reload

      render json: @attack_pattern
    else
      respond_to do |format|
        format.any(:html,:json) do
          render json: {errors: ["Could not find Attack Pattern with ID: #{params[:id]}"]}, status: 404
        end
      end
    end
  end

  def update
    @attack_pattern = AttackPattern.find_by_stix_id(params[:id])
    
    if (!Permissions.can_be_modified_by(current_user, @attack_pattern))
      render json: {errors: ["You do not have the ability to modify Attack Patterns"]}, status: 403
      return
    end

    @attack_pattern.update(attack_pattern_params)

    validation_errors = {:base => []}

    if @attack_pattern.errors.present?
      validation_errors[:base] << @attack_pattern.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @attack_pattern
    else
      render json: {errors: validation_errors}, status: 403
    end
  end

  def destroy
    @attack_pattern = AttackPattern.find_by_stix_id(params[:id])
    if !User.has_permission(current_user, 'create_remove_attack_patterns') || !Permissions.can_be_deleted_by(current_user, @attack_pattern)
      render json: {errors: ["You do not have the ability to delete Attack Patterns"]}, status: 403
      return
    end
    if @attack_pattern.destroy
      head 204
    else
      render json: {errors:{} },status: :unprocessable_entity
    end
  end

private

  def attack_pattern_params
    params.permit(:stix_id,
                  :title,
                  :description,
                  :capec_id,
                  STIX_MARKING_PERMITTED_PARAMS)
  end

end
