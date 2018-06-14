class CourseOfActionsController < ApplicationController
  include StixMarkingHelper

  before_filter :isa_params, only: [:create,:update]
  
  def index
    @course_of_actions = CourseOfAction.where(:stix_id => params[:ids]) if params[:ids]
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
      search = Search.course_of_action_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset
      })

      if marking_search_params.present?
        @course_of_actions ||= CourseOfAction.all.reorder(updated_at: :desc).includes(:created_by_user)
        @course_of_actions = @course_of_actions.where(id: search.results.collect {|coa| coa.id})
      else
        total_count = search.total
        @course_of_actions = search.results
      end

      @course_of_actions ||= []
    else
      @course_of_actions ||= CourseOfAction.all.reorder(updated_at: :desc).includes(:created_by_user)

      @course_of_actions = @course_of_actions.where(updated_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @course_of_actions = @course_of_actions.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
      @course_of_actions = @course_of_actions.classification_greater(params[:classification_greater]) if params[:classification_greater] && Classification::CLASSIFICATIONS.include?(params[:classification_greater])
      @course_of_actions = apply_sort(@course_of_actions, params)
    end

    if marking_search_params.present?
      # We need to search markings both that are attached to this object or that may be
      # available through an AcsSet. Since Rails doesn't support Unions, we need to make it
      # it through straight sql
      
      # We need to limit the columns being queried to eliminate CLOB columns. Oracle doesn't like
      # CLOB columns in a FROM clause. Limit to only the columns in the grid or required by the query
      # Remove any existing ordering as it will create invalid SQL
      from_query = @course_of_actions.reorder('').select("course_of_actions.id as id, " +
          "course_of_actions.stix_id as stix_id, course_of_actions.guid as guid, " +
             "course_of_actions.acs_set_id as acs_set_id, course_of_actions.title as title, " +
             "course_of_actions.description_normalized as description_normalized, " +
             "course_of_actions.created_at as created_at, course_of_actions.updated_at as updated_at")
      
      scope_normal = from_query.joins(:stix_markings)
      scope_normal = add_stix_markings_constraints(scope_normal, marking_search_params)
      
      scope_acs = from_query.joins(:acs_set).joins("JOIN stix_markings ON stix_markings.remote_object_id = acs_sets.guid and stix_markings.remote_object_type = 'AcsSet'")
      scope_acs = add_stix_markings_constraints(scope_acs, marking_search_params)
      
      order = sanitize_sort_order(CourseOfAction.column_names, params[:column])
      direction = sanitize_sort_direction(params[:direction])
      
      partial_results = CourseOfAction.from("(#{scope_normal.to_sql} UNION #{scope_acs.to_sql} ORDER BY #{order} #{direction}) course_of_actions")

      total_count = partial_results.count
      partial_results = partial_results.limit(limit).offset(offset)
              
      # Now requery to get the full objects
      @course_of_actions = CourseOfAction.where(id: partial_results.collect{|rslt| rslt.id})
      @course_of_actions = apply_sort(@course_of_actions, params)
    end
    
    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @course_of_actions.count
      @course_of_actions = @course_of_actions.limit(limit).offset(offset)
    end

    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, course_of_actions: @course_of_actions} }
      format.csv {render "course_of_actions/index.csv.erb"}
    end
  end

  def create
    if !User.has_permission(current_user, 'create_remove_course_of_actions')
      render json: {errors: ["You do not have the ability to create courses of action"]}, status: 403
      return
    end
    
    if params[:acs_set_id].present?
      unless AcsSet.for_org(User.current_user.organization).collect(&:guid).include?(params[:acs_set_id])
        render json: {errors: ["You do not have the ability to associate this object with this ACS Set"]}, status: 403
        return
      end
    end

    if User.has_permission(current_user,'link_indicators_to_course_of_actions')
      params[:indicator_stix_ids] ||= []
    end
    
    if User.has_permission(current_user,'link_packages_to_course_of_actions')
      params[:stix_package_stix_ids] ||= []
    end

    @course_of_action = CourseOfAction.new(course_of_action_params)

    if params[:indicator_stix_ids].length > 0
      if !User.has_permission(current_user,'link_indicators_to_course_of_actions')
        render json: {errors: ["You do not have the ability to add indicator to course of action"]}, status: 403
        return
      end
      @course_of_action.indicator_stix_ids = params[:indicator_stix_ids]||[]
    end
    
    if params[:stix_package_stix_ids].length > 0
      if !User.has_permission(current_user,'link_packages_to_course_of_actions')
        render json: {errors: ["You do not have the ability to add package to course of action"]}, status: 403
        return
      end
      @course_of_action.stix_package_stix_ids = params[:stix_package_stix_ids]||[]
    end

    validate(@course_of_action)

    validation_errors = {:base => []}

    # Look through all the indicators_course_of_actions and find errors. Add them to the errors array.
    @course_of_action.indicators_course_of_actions.each do |ita|
      if ita.errors.messages.present? && ita.errors.messages[:base].present?
        ita.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end
        
    # Look through all the packages_course_of_actions and find errors. Add them to the errors array.
    @course_of_action.packages_course_of_actions.each do |ita|
      if ita.errors.messages.present? && ita.errors.messages[:base].present?
        ita.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # if validate comes back with errors, we probably have a error in indicators_course_of_actions
    unless validation_errors[:base].blank?
      render json: {errors: validation_errors}, status: 403
      return
    end
  end

  def show
    @course_of_action = CourseOfAction.includes(
        :indicators,
        audits: :user,
        stix_markings: [:isa_marking_structure,:tlp_marking_structure,:simple_marking_structure,{isa_assertion_structure: [:isa_privs,:further_sharings]}],
        observables: [:address,{file: :file_hashes},:mutex,
                      :dns_record,:domain,:email_message,:http_session, :hostname, :port, :socket_address,
                      :network_connection,{registry: :registry_values},
                      :uri,{link: :uri}],
        parameter_observables: [:address,{file: :file_hashes},:mutex,
                      :dns_record,:domain,:email_message,:http_session, :hostname, :port, :socket_address,
                      :network_connection,{registry: :registry_values},
                      :uri,{link: :uri}]
    ).find_by_stix_id(params[:id])

    if @course_of_action
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      CourseOfAction.apply_default_policy_if_needed(@course_of_action)
      @course_of_action.reload

      respond_to do |format|
        format.any(:html,:json) do
          render json: @course_of_action
        end
        format.stix do
          audit = Audit.basic
          audit.item = @course_of_action
          audit.audit_type = :stix_download
          audit.message = "Course Of Action Downloaded as STIX"
          audit.user = current_user
          @course_of_action.audits << audit

          stream = render_to_string(template: "course_of_actions/package.stix")
          send_data(stream, type: "text/xml", filename: "#{@course_of_action.stix_id}.xml")
        end
        format.ais do
          audit = Audit.basic
          audit.item = @course_of_action
          audit.audit_type = :ais_download
          audit.message = "Course Of Action Downloaded as AIS"
          audit.user = current_user
          @course_of_action.audits << audit

          stream = render_to_string(template: "course_of_actions/package.ais")
          send_data(stream, type: "text/xml", filename: "#{@course_of_action.stix_id}.xml")
        end
      end
    else
      respond_to do |format|
        format.any(:html,:json) do
          render json: {errors: ["Could not find course of action with ID: #{params[:id]}"]}, status: 404
        end
        format.any(:stix,:ais) do
          render xml: {errors: ["Could not find course of action with ID: #{params[:id]}"]}, status: 404
        end
      end
    end
  end

  def update
    if User.has_permission(current_user,'link_indicators_to_course_of_actions')
      params[:indicator_stix_ids] ||= []
    end
    
    if User.has_permission(current_user,'link_packages_to_course_of_actions')
      params[:stix_package_stix_ids] ||= []
    end

    @course_of_action = CourseOfAction.find_by_stix_id(params[:id])

    if params[:indicator_stix_ids].length > 0 || @course_of_action.indicators.length != params[:indicator_stix_ids].length
      if !User.has_permission(current_user,'link_indicators_to_course_of_actions')
        render json: {errors: ["You do not have the ability to add indicators to course of action"]}, status: 403
        return
      end
      @course_of_action.indicator_stix_ids = params[:indicator_stix_ids]||[]
    elsif (!Permissions.can_be_modified_by(current_user, @course_of_action))
      render json: {errors: ["You do not have the ability to modify course of action"]}, status: 403
      return
    end
    
    if params[:stix_package_stix_ids].length > 0 || @course_of_action.stix_packages.length != params[:stix_package_stix_ids].length
      if !User.has_permission(current_user,'link_packages_to_course_of_actions')
        render json: {errors: ["You do not have the ability to add packages to course of action"]}, status: 403
        return
      end
      @course_of_action.stix_package_stix_ids = params[:stix_package_stix_ids]||[]
    elsif (!Permissions.can_be_modified_by(current_user, @course_of_action))
      render json: {errors: ["You do not have the ability to modify course of action"]}, status: 403
      return
    end

    if params[:acs_set_id].present?
      unless AcsSet.for_org(User.current_user.organization).collect(&:guid).include?(params[:acs_set_id])
        render json: {errors: ["You do not have the ability to associate this object with this ACS Set"]}, status: 403
        return
      end
    end

    Audit.justification = params[:justification] if params[:justification]
    @course_of_action.update(course_of_action_params)
    validate(@course_of_action)

    validation_errors = {:base => []}

    # Look through all the indicators_course_of_actions and find errors. Add them to the errors array.   
    @course_of_action.indicators_course_of_actions.each do |ita|
      if ita.errors.messages.present? && ita.errors.messages[:base].present?
        ita.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end
    
    # Look through all the packages_course_of_actions and find errors. Add them to the errors array.
    @course_of_action.packages_course_of_actions.each do |ita|
      if ita.errors.messages.present? && ita.errors.messages[:base].present?
        ita.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # if validate comes back with errors, we probably have a error in indicators_course_of_actions
    unless validation_errors[:base].blank?
      render json: {errors: validation_errors}, status: 403
      return
    end
  end

  def destroy
    @course_of_action = CourseOfAction.find_by_stix_id(params[:id])
    if !User.has_permission(current_user, 'create_remove_course_of_actions') || !Permissions.can_be_deleted_by(current_user, @course_of_action)
      render json: {errors: ["You do not have the ability to delete courses of action"]}, status: 403
      return
    end
    if @course_of_action.destroy
      head 204
    else
      render json: {errors:{} },status: :unprocessable_entity
    end
  end

private

  def validate(object)
    if object.save
      render json: object
    else
      render json: {errors: object.errors}, status: :unprocessable_entity
    end
  end

  def course_of_action_params
    # Handle deep_munge and allow empty set
    params[:indicator_stix_ids] ||= []
    
    params[:stix_package_stix_ids] ||= []

    params.permit(:title,
                  :stix_id,  
                  :description,
                  :acs_set_id,            
                  STIX_MARKING_PERMITTED_PARAMS,
                  :indicator_stix_ids => [],
                  :stix_package_stix_ids => []
    )
  end

end
