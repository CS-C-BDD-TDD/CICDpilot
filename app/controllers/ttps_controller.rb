class TtpsController < ApplicationController
  include StixMarkingHelper

  def index
    @ttps = Ttp.where(:stix_id => params[:ids]) if params[:ids]
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
      search = Search.ttp_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        classification_limit: params[:classification_limit],
        offset: solr_offset
      })

      if marking_search_params.present?
        @ttps ||= Ttp.all.reorder(updated_at: :desc).includes(:created_by_user)
        @ttps = @ttps.where(id: search.results.collect {|ttp| ttp.id})
      else
        total_count = search.total
        @ttps = search.results
      end

      @ttps ||= []
    else
      @ttps ||= Ttp.all.reorder(updated_at: :desc).includes(:created_by_user)

      @ttps = @ttps.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      
      @ttps = @ttps.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
      @ttps = @ttps.classification_greater(params[:classification_greater]) if params[:classification_greater] && Classification::CLASSIFICATIONS.include?(params[:classification_greater])
      @ttps = apply_sort(@ttps, params)
    end

    if marking_search_params.present?
      # We need to search markings both that are attached to this object or that may be
      # available through an AcsSet. Since Rails doesn't support Unions, we need to make it
      # it through straight sql
      
      # We need to limit the columns being queried to eliminate CLOB columns. Oracle doesn't like
      # CLOB columns in a FROM clause. Limit to only the columns in the grid or required by the query
      # Remove any existing ordering as it will create invalid SQL
      from_query = @ttps.reorder('').select("ttps.id as id, " +
          "ttps.stix_id as stix_id, ttps.guid as guid, " +
             "ttps.acs_set_id as acs_set_id, " +
             "ttps.created_at as created_at, ttps.updated_at as updated_at")
      
      scope_normal = from_query.joins(:stix_markings)
      scope_normal = add_stix_markings_constraints(scope_normal, marking_search_params)
      
      scope_acs = from_query.joins(:acs_set).joins("JOIN stix_markings ON stix_markings.remote_object_id = acs_sets.guid and stix_markings.remote_object_type = 'AcsSet'")
      scope_acs = add_stix_markings_constraints(scope_acs, marking_search_params)
      
      order = sanitize_sort_order(Ttp.column_names, params[:column])
      direction = sanitize_sort_direction(params[:direction])
      
      partial_results = Ttp.from("(#{scope_normal.to_sql} UNION #{scope_acs.to_sql} ORDER BY #{order} #{direction}) ttps")

      total_count = partial_results.count
      partial_results = partial_results.limit(limit).offset(offset)
              
      # Now requery to get the full objects
      @ttps = Ttp.where(id: partial_results.collect{|rslt| rslt.id})
      @ttps = apply_sort(@ttps, params)
    end
    
    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @ttps.count
      @ttps = @ttps.limit(limit).offset(offset)
    end

    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, ttps: @ttps} }
      format.csv {render "ttps/index.csv.erb"}
    end
  end

  def create
    if !User.has_permission(current_user, 'create_remove_ttps')
      render json: {errors: ["You do not have the ability to create TTPs"]}, status: 403
      return
    end
    
    if params[:acs_set_id].present?
      unless AcsSet.for_org(User.current_user.organization).collect(&:guid).include?(params[:acs_set_id])
        render json: {errors: ["You do not have the ability to associate this object with this ACS Set"]}, status: 403
        return
      end
    end

    if User.has_permission(current_user,'add_ttp_to_indicators')
      params[:indicator_stix_ids] ||= []
    end

    if User.has_permission(current_user,'add_ttp_to_stix_packages')
      params[:stix_package_stix_ids] ||= []
    end

    if User.has_permission(current_user,'add_attack_patterns_to_ttps')
      params[:attack_pattern_stix_ids] ||= []
    end

    if User.has_permission(current_user,'add_exploit_targets_to_ttps')
      params[:exploit_target_stix_ids] ||= []
    end

    validation_errors = {:base => []}
    
    @ttp = Ttp.new(ttp_params)
    
    if params[:indicator_stix_ids].length > 0
      if !User.has_permission(current_user,'add_ttp_to_indicators')
        render json: {errors: ["You do not have the ability to add TTPs to Indicators"]}, status: 403
        return
      end
      @ttp.indicator_stix_ids = params[:indicator_stix_ids] || []
    end

    if params[:stix_package_stix_ids].length > 0
      if !User.has_permission(current_user,'add_ttp_to_stix_packages')
        render json: {errors: ["You do not have the ability to add TTPs to STIX Packages"]}, status: 403
        return
      end
      @ttp.stix_package_stix_ids = params[:stix_package_stix_ids] || []
    end

    if params[:attack_pattern_stix_ids].length > 0
      if !User.has_permission(current_user,'add_attack_patterns_to_ttps')
        render json: {errors: ["You do not have the ability to add attack patterns to TTPs"]}, status: 403
        return
      end
      @ttp.attack_pattern_stix_ids = params[:attack_pattern_stix_ids]||[]
    end

    if params[:exploit_target_stix_ids].length > 0
      if !User.has_permission(current_user,'add_exploit_targets_to_ttps')
        render json: {errors: ["You do not have the ability to add exploit targets to TTPs"]}, status: 403
        return
      end
      @ttp.exploit_target_stix_ids = params[:exploit_target_stix_ids]||[]
    end

    begin
      @ttp.save!
    rescue Exception => e
      validation_errors[:base] << e.to_s
    end

    # Look through all the ttp_attack_patterns and find errors. Add them to the errors array.
    @ttp.ttp_attack_patterns.each do |tap|
      if tap.errors.messages.present? && tap.errors.messages[:base].present?
        tap.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # Look through all the ttp_exploit_targets and find errors. Add them to the errors array.
    @ttp.ttp_exploit_targets.each do |tet|
      if tet.errors.messages.present? && tet.errors.messages[:base].present?
        tet.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    if @ttp.errors.present?
      validation_errors[:base] << @ttp.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @ttp
    else
      render json: {errors: validation_errors}, status: 403
    end
  end

  def show
    @ttp = Ttp.includes(audits: :user, stix_markings: [:isa_marking_structure, :tlp_marking_structure, :simple_marking_structure, {isa_assertion_structure: [:isa_privs,:further_sharings]}]).find_by_stix_id(params[:id])

    if @ttp
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Ttp.apply_default_policy_if_needed(@ttp)
      @ttp.reload

      respond_to do |format|
        format.any(:html,:json) do
          render json: @ttp
        end
        format.stix do
          audit = Audit.basic
          audit.item = @ttp
          audit.audit_type = :stix_download
          audit.message = "TTP Downloaded as STIX"
          audit.user = current_user
          @ttp.audits << audit

          stream = render_to_string(template: "ttps/package.stix")
          send_data(stream, type: "text/xml", filename: "#{@ttp.stix_id}.xml")
        end
        format.ais do
          audit = Audit.basic
          audit.item = @ttp
          audit.audit_type = :ais_download
          audit.message = "TTP Downloaded as AIS"
          audit.user = current_user
          @ttp.audits << audit

          stream = render_to_string(template: "ttps/package.ais")
          send_data(stream, type: "text/xml", filename: "#{@ttp.stix_id}.xml")
        end
      end
    else
      respond_to do |format|
        format.any(:html,:json) do
          render json: {errors: ["Could not find TTP with ID: #{params[:id]}"]}, status: 404
        end
        format.any(:stix,:ais) do
          render xml: {errors: ["Could not find TTP with ID: #{params[:id]}"]}, status: 404
        end
      end
    end
  end

  def update
    @ttp = Ttp.find_by_stix_id(params[:id])
    
    if (!Permissions.can_be_modified_by(current_user, @ttp))
      render json: {errors: ["You do not have the ability to modify TTPs"]}, status: 403
      return
    end

    if User.has_permission(current_user,'add_ttp_to_indicators')
      params[:indicator_stix_ids] ||= []
    end

    if User.has_permission(current_user,'add_ttp_to_stix_packages')
      params[:stix_package_stix_ids] ||= []
    end

    if User.has_permission(current_user,'add_attack_patterns_to_ttps')
      params[:attack_pattern_stix_ids] ||= []
    end

    if User.has_permission(current_user,'add_exploit_targets_to_ttps')
      params[:exploit_target_stix_ids] ||= []
    end

    if params[:indicator_stix_ids].length > 0
      if !User.has_permission(current_user,'add_ttp_to_indicators')
        render json: {errors: ["You do not have the ability to add TTPs to STIX Packages"]}, status: 403
        return
      end
      @ttp.indicator_stix_ids = params[:indicator_stix_ids] || []
    end

    if params[:stix_package_stix_ids].length > 0
      if !User.has_permission(current_user,'add_ttp_to_stix_packages')
        render json: {errors: ["You do not have the ability to add TTPs to STIX Packages"]}, status: 403
        return
      end
      @ttp.stix_package_ids = params[:stix_package_ids] || []
    end

    if params[:attack_pattern_stix_ids].length > 0
      if !User.has_permission(current_user,'add_attack_patterns_to_ttps')
        render json: {errors: ["You do not have the ability to add attack patterns to TTPs"]}, status: 403
        return
      end
      @ttp.attack_pattern_stix_ids = params[:attack_pattern_stix_ids] || []
    end

    if params[:exploit_target_stix_ids].length > 0
      if !User.has_permission(current_user,'add_exploit_targets_to_ttps')
        render json: {errors: ["You do not have the ability to add exploit_targets to TTPs"]}, status: 403
        return
      end
      @ttp.exploit_target_stix_ids = params[:exploit_target_stix_ids] || []
    end

    if params[:acs_set_id].present?
      unless AcsSet.for_org(User.current_user.organization).collect(&:guid).include?(params[:acs_set_id])
        render json: {errors: ["You do not have the ability to associate this object with this ACS Set"]}, status: 403
        return
      end
    end
    
    Audit.justification = params[:justification] if params[:justification]
    @ttp.update(ttp_params)

    validation_errors = {:base => []}

    # Look through all the attack patterns and find errors. Add them to the errors array.
    @ttp.attack_patterns.each do |tb|
      if tb.errors.messages.present? && tb.errors.messages[:base].present?
        tb.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # Look through all the exploit_targets and find errors. Add them to the errors array.
    @ttp.exploit_targets.each do |tet|
      if tet.errors.messages.present? && tet.errors.messages[:base].present?
        tet.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    if @ttp.errors.present?
      validation_errors[:base] << @ttp.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @ttp
    else
      render json: {errors: validation_errors}, status: 403
    end
  end

  def destroy
    @ttp = Ttp.find_by_stix_id(params[:id])
    if !User.has_permission(current_user, 'create_remove_ttps') || !Permissions.can_be_deleted_by(current_user, @ttp)
      render json: {errors: ["You do not have the ability to delete TTPs"]}, status: 403
      return
    end
    if @ttp.destroy
      head 204
    else
      render json: {errors:{} },status: :unprocessable_entity
    end
  end

private

  def ttp_params
    # Handle deep_munge and allow empty set
    params[:indicator_stix_ids] ||= []
    params[:stix_package_stix_ids] ||= []
    params[:attack_pattern_stix_ids] ||= []
    params[:exploit_target_stix_ids] ||= []

    params.permit(:stix_id,
                  :acs_set_id,
                  :indicator_stix_id,
                  STIX_MARKING_PERMITTED_PARAMS,
                  :indicator_stix_ids => [],
                  :stix_package_stix_ids => [],
                  :attack_pattern_stix_ids => [],
                  :exploit_target_stix_ids => [])
  end

end
