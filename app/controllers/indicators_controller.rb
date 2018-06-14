class IndicatorsController < ApplicationController
  include StixMarkingHelper
  
  before_filter :isa_params, only: [:create,:update]

  def index
    limit = params[:replication_test] ? 1 : record_limit(params[:amount].to_i)
    offset = params[:offset] || 0
    locals = {associations: {observables: 'embedded'}}
    marking_search_params = nil

    if params[:marking_search_params].present?
      marking_search_params = JSON.parse params[:marking_search_params]
    end
    
    @indicators ||= Indicator.where(:stix_id => params[:ids]) if params[:ids]

    if params[:title_q].present? || params[:reference_q].present? || params[:threat_actor_q].present? || params[:observable_q].present? || params[:observable_type].present? || params[:column] == "observable_value"
      solr_offset = offset
      solr_limit = limit
      
      # If performing a SOLR based search AND a Stix Marking search we need to do a two-step query
      # First, we perform the SOLR based query and grab the ids of the first 1000 results.
      # We use those IDs to limit the SQL query that will feed the Stix Marking search
      if marking_search_params.present?
        solr_offset = 0
        solr_limit = 1000
      end
      search = Search.indicator_filter_search({
        q: params[:q],
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        indicator_type: params[:indicator_type],
        observable_type: params[:observable_type],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset,
        title_q: params[:title_q],
        reference_q: params[:reference_q],
        observable_q: params[:observable_q],
        threat_actor_q: params[:threat_actor_q],
        is_ais: params[:is_ais].to_bool
      })
      
      if marking_search_params.present?
        @indicators ||= Indicator.all.reorder(updated_at: :desc).includes(:confidences, :official_confidence)
        @indicators = @indicators.where(id: search.results.collect {|ind| ind.id})
      else
        total_count = search.total
        @indicators = search.results
        locals[:associations].merge!(created_by_user: 'embedded')
      end

      @indicators ||= []
    elsif params[:q].present?
      # If performing a SOLR based search AND a Stix Marking search we need to do a two-step query
      # First, we perform the SOLR based query and grab the ids of the first 1000 results.
      # We use those IDs to limit the SQL query that will feed the Stix Marking search
      if marking_search_params.present?
        offset = 0
        limit = 1000
      end
      search = Search.indicator_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        indicator_type: params[:indicator_type],
        observable_type: params[:observable_type],
        limit: (limit || Sunspot.config.pagination.default_per_page),
        offset: offset,
        system_tag_id: params[:system_tag_id],
        classification_limit: params[:classification_limit],
        classification_greater: params[:classification_greater],
        exclude_weather_map: params[:exclude_weather_map],
        is_ais: params[:is_ais].to_bool
      })

      if marking_search_params.present?
        @indicators ||= Indicator.all.reorder(updated_at: :desc).includes(:confidences, :official_confidence)
        @indicators = @indicators.where(id: search.results.collect {|ind| ind.id})
      else
        total_count = search.total
        @indicators = search.results
        locals[:associations].merge!(created_by_user: 'embedded')
      end

      @indicators ||= []
    else
      @indicators ||= Indicator.all.reorder(updated_at: :desc).includes(:confidences, :official_confidence)
      
      @indicators = @indicators.where(updated_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @indicators = @indicators.where(is_ais: params[:is_ais].to_bool) if params[:is_ais].present? && params[:is_ais].to_bool == true
      @indicators = @indicators.where(indicator_type: params[:indicator_type]) if params[:indicator_type].present?
      @indicators = @indicators.where(observable_type: params[:observable_type]) if params[:observable_type].present?
      @indicators = @indicators.joins(:system_tags).where("tag_assignments.tag_guid = ?",params[:system_tag_id]) if params[:system_tag_id].present?
      @indicators = @indicators.joins(:user_tags).where(:tags => {user_guid: current_user.guid},:tag_assignments => {tag_guid: params[:user_tag_id]} ) if params[:user_tag_id]
      @indicators = @indicators.where(dms_label: params[:dms_label]) if params[:dms_label].present?
      @indicators = @indicators.joins(:addresses).where(cybox_addresses: {cybox_object_id: params[:address_cybox_id]}) if params[:address_cybox_id]
      @indicators = @indicators.joins(:domains).where(cybox_domains: {cybox_object_id: params[:domain_cybox_id]}) if params[:domain_cybox_id]
      @indicators = @indicators.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
      @indicators = @indicators.classification_greater(params[:classification_greater]) if params[:classification_greater] && Classification::CLASSIFICATIONS.include?(params[:classification_greater])
      @indicators = apply_sort(@indicators, params)
    end

    if marking_search_params.present?
      # We need to search markings both that are attached to this object or that may be
      # available through an AcsSet. Since Rails doesn't support Unions, we need to make it
      # it through straight sql
      
      # Special handling for the one CLOB field that we have to sort on
      obsv_sql = "stix_indicators.observable_value as observable_value, " 
      if ActiveRecord::Base.connection.instance_values["config"][:adapter].starts_with? 'oracle'
        obsv_sql = "dbms_lob.substr(stix_indicators.observable_value, 2000, 1) as observable_value, " 
      end
             
      # We need to limit the columns being queried to eliminate CLOB columns. Oracle doesn't like
      # CLOB columns in a FROM clause. Limit to only the columns in the grid or required by the query
      # Remove any existing ordering as it will create invalid SQL
      from_query = @indicators.reorder('').select("stix_indicators.id as id, " +
          "stix_indicators.stix_id as stix_id, stix_indicators.guid as guid, " +
          "stix_indicators.acs_set_id as acs_set_id, " + obsv_sql +
          "stix_indicators.observable_type as observable_type, " +
          "stix_indicators.indicator_type as indicator_type, " +
          "stix_indicators.title as title, stix_indicators.updated_at as updated_at")
      
      scope_normal = from_query.joins(:stix_markings)
      scope_normal = add_stix_markings_constraints(scope_normal, marking_search_params)
      
      scope_acs = from_query.joins(:acs_set).joins("JOIN stix_markings ON stix_markings.remote_object_id = acs_sets.guid and stix_markings.remote_object_type = 'AcsSet'")
      scope_acs = add_stix_markings_constraints(scope_acs, marking_search_params)
      
      order = sanitize_sort_order(Indicator.column_names, params[:column])
      direction = sanitize_sort_direction(params[:direction])
      
      partial_results = Indicator.from("(#{scope_normal.to_sql} UNION #{scope_acs.to_sql} ORDER BY #{order} #{direction}) stix_indicators")

      total_count = partial_results.count
      partial_results = partial_results.limit(limit).offset(offset)
              
      # Now requery to get the full objects
      @indicators = Indicator.where(id: partial_results.collect{|rslt| rslt.id})
      @indicators = apply_sort(@indicators, params)
    end
    
    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @indicators.count
      @indicators = @indicators.limit(limit).offset(offset)
    end
    
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, indicators: @indicators} }
      format.csv {render "indicators/index.csv.erb"}
    end
  end

  def public_indicators
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0
    locals = {associations: {observables: 'embedded'}}
    @indicators ||= Indicator.all.reorder(updated_at: :desc).includes(
          stix_markings: :isa_marking_structures,observables: [:address,:domain,:uri,
          :email_message,:mutex,:http_session, :hostname, :port,
          :dns_record,:network_connection,file: :file_hashes, registry: :registry_values])

    @indicators = @indicators.where(updated_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
    @indicators = apply_sort(@indicators, params)
    @indicators = @indicators.where(indicator_type: params[:indicator_type]) if params[:indicator_type].present?
    @indicators = @indicators.joins(:system_tags).where("tag_assignments.tag_guid = ?",params[:system_tag_id]) if params[:system_tag_id].present?
    @indicators = @indicators.where(dms_label: params[:dms_label]) if params[:dms_label].present?
    @indicators = @indicators.where(public_release: true)
    @indicators = @indicators.preload(:official_confidence)
    total_count ||= @indicators.count
    @indicators = @indicators.limit(limit).offset(offset)
    @metadata = Metadata.new
    @metadata.total_count = total_count
    render json: {metadata: {system_guid: Setting.SYSTEM_GUID},indicators: @indicators}, serializer: Public::IndicatorSerializer
  end

  def weather_map_indicators
    #TODO determine what to do with this
    limit = record_limit(params[:amount].to_i)
    @indicators = Indicator.all.reorder(updated_at: :desc)
    @indicators = @indicators.where(updated_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
    @indicators = @indicators.joins(:weather_map_addresses)
    @indicators = @indicators.joins(:weather_map_domains)
    @indicators = apply_sort(@indicators, params)
    @indicators = @indicators.limit(limit)
    @indicators = @indicators.where(public_release: true)
    @indicators = @indicators.includes(stix_markings: :isa_marking_structures,observables: [:address,:domain,:uri,
                                                                                                  :email_message,:mutex,:http_session, :hostname, :port,
                                                                                                  :dns_record,:network_connection,file: :file_hashes, registry: :registry_values])

    @indicators = @indicators.preload(:weather_map_addresses)
    @indicators = @indicators.preload(:weather_map_domains)
    @indicators = @indicators.preload(:official_confidence)

    render json: {metadata: {system_guid: Setting.SYSTEM_GUID},indicators: @indicators}, serializer: Public::IndicatorSerializer
  end

  def show
    @indicator = Indicator.includes(
        :attachments,
        :addresses,
        :weather_map_addresses,
        :domains,
        :weather_map_domains,
        audits: :user,
        confidences: :user,
        sightings: [:user, {confidences: :user}],
        related_to_objects: [confidences: :user],
        related_by_objects: [confidences: :user],
        stix_markings: [:isa_marking_structure,:tlp_marking_structure,:simple_marking_structure,{isa_assertion_structure: [:isa_privs,:further_sharings]}],
        observables: [:address,{file: :file_hashes},:mutex,
                      :dns_record,:domain,:email_message,:http_session,:hostname, :port, :socket_address,
                      :network_connection,{registry: :registry_values},
                      :uri]
    ).find_by_stix_id(params[:id])

    if @indicator
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Indicator.apply_default_policy_if_needed(@indicator)
      @indicator.reload

      respond_to do |format|
        format.any(:html,:json) do
          render json: @indicator
        end
        format.stix do
          audit = Audit.basic
          audit.item = @indicator
          audit.audit_type = :stix_download
          audit.message = "Indicator Downloaded as STIX"
          audit.user = current_user
          @indicator.audits << audit

          stream = render_to_string(template: "indicators/package.stix")
          send_data(stream, type: "text/xml", filename: "#{@indicator.stix_id}.xml")
        end
        format.ais do
          audit = Audit.basic
          audit.item = @indicator
          audit.audit_type = :ais_download
          audit.message = "Indicator Downloaded as AIS"
          audit.user = current_user
          @indicator.audits << audit

          stream = render_to_string(template: "indicators/package.ais")
          send_data(stream, type: "text/xml", filename: "#{@indicator.stix_id}.xml")
        end
      end
    else
      respond_to do |format|
        format.any(:html,:json) do
          render json: {errors: ["Could not find indicator with ID: #{params[:id]}"]}, status: 404
        end
        format.any(:stix,:ais) do
          render xml: {errors: ["Could not find indicator with ID: #{params[:id]}"]}, status: 404
        end
      end
    end
  end

  def create

    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create indicators"]}, status: 403
      return
    end

    if User.has_permission(current_user,'tag_item_with_system_tag')
      params[:system_tag_ids] ||= []
    end

    if User.has_permission(current_user,'tag_item_with_user_tag')
      params[:user_tag_ids] ||= []
    end

    if Indicator.find_by_stix_id(indicator_params[:stix_id])
      render json: {errors: ["This indicator already exists in the system."]},status: 409
      return
    end

    if User.has_permission(current_user,'add_ttp_to_indicators')
      params[:ttp_stix_ids] ||= []
    end

    @indicator = Indicator.new indicator_params

    acs_set = params[:acs_set_id] == 'default' ? AcsSet.find_by_name('Default Markings for Weather Map') : nil
    address = params[:address] ? Address.find_by_cybox_object_id(params[:address]) : nil
    domain = params[:domain] ? Domain.find_by_cybox_object_id(params[:domain]) : nil
    @indicator.acs_set = acs_set if acs_set.present?

    if params[:system_guid]
      @indicator.received_from_system_guid = params[:system_guid]
    end

    if params[:user_tag_ids]
      if !User.has_permission(current_user,'tag_item_with_user_tag')
        render json: {errors: ["You do not have the ability to update user tags"]}, status: 403
        return
      end
      @indicator.user_tag_ids = params[:user_tag_ids]||[]
    end

    if params[:system_tag_ids]
      if !User.has_permission(current_user,'tag_item_with_system_tag')
        render json: {errors: ["You do not have the ability to update system tags"]}, status: 403
        return
      end
      @indicator.system_tag_ids = params[:system_tag_ids]||[]
    end

    if params[:acs_set_id].present? && acs_set.blank?
      unless AcsSet.for_org(User.current_user.organization).collect(&:guid).include?(params[:acs_set_id])
        render json: {errors: ["You do not have the ability to associate this object with this ACS Set"]}, status: 403
        return
      end
    end

    if params[:timelines] || params[:source_of_report] || params[:target_of_attack] || params[:target_scope] || params[:actor_attribution] || params[:actor_type] || params[:modus_operandi]
      if !User.has_permission(current_user,'create_modify_indicator_scoring')
        render json: {errors: ["You do not have the ability to create/edit indicator scoring."]}, status: 403
        return
      end
    end

    if params[:ttp_stix_ids].length > 0
      if !User.has_permission(current_user,'add_ttp_to_indicators')
        render json: {errors: ["You do not have the ability to add ttps to indicators"]}, status: 403
        return
      end
      @indicator.ttp_stix_ids = params[:ttp_stix_ids] || []
    end

    if @indicator.save
      update_kill_chains(params[:kill_chain_phases])
      Observable.create(object: address, indicator: @indicator) if address.present?
      Observable.create(object: domain, indicator: @indicator) if domain.present?
      render(json: @indicator, status: :created)
      return
    else
      render json: {errors: @indicator.errors}, status: :unprocessable_entity
    end
  end

  def update
    @indicator = Indicator.find_by_stix_id(params[:id])

    if (!Permissions.can_be_modified_by(current_user, @indicator))
      render json: {errors: ["You do not have the ability to modify indicators"]}, status: 403
      return
    end

    if User.has_permission(current_user,'tag_item_with_system_tag')
      params[:system_tag_ids] ||= []
    end


    if User.has_permission(current_user,'tag_item_with_user_tag')
      params[:user_tag_ids] ||= []
    end

    if params[:user_tag_ids]
      if !User.has_permission(current_user,'tag_item_with_user_tag')
        render json: {errors: ["You do not have the ability to update user tags"]}, status: 403
        return
      end
      @indicator.update_user_tag_ids(current_user,params[:user_tag_ids]||[])
    end

    if params[:system_tag_ids]
      if !User.has_permission(current_user,'tag_item_with_system_tag')
        render json: {errors: ["You do not have the ability to update system tags"]}, status: 403
        return
      end
      @indicator.system_tag_ids = params[:system_tag_ids]||[]
    end

    if params[:acs_set_id].present?
      unless AcsSet.for_org(User.current_user.organization).collect(&:guid).include?(params[:acs_set_id])
        render json: {errors: ["You do not have the ability to associate this object with this ACS Set"]}, status: 403
        return
      end
    end

    if params[:timelines] || params[:source_of_report] || params[:target_of_attack] || params[:target_scope] || params[:actor_attribution] || params[:actor_type] || params[:modus_operandi]
      if !User.has_permission(current_user,'create_modify_indicator_scoring')
        render json: {errors: ["You do not have the ability to create/edit indicator scoring."]}, status: 403
        return
      end
    end

    if User.has_permission(current_user,'add_ttp_to_indicators')
      params[:ttp_stix_ids] ||= []
    end

    if params[:ttp_stix_ids].length > 0
      if !User.has_permission(current_user,'add_ttp_to_indicators')
        render json: {errors: ["You do not have the ability to add ttps to indicators"]}, status: 403
        return
      end
      # Check classification levels
      params[:ttp_stix_ids].each do |ttp_id|
        test_ttp = Ttp.find_by_stix_id(ttp_id)
        
        if test_ttp.present? && @indicator.portion_marking.present? && test_ttp.portion_marking.present? && Classification::CLASSIFICATIONS.index(@indicator.portion_marking) < Classification::CLASSIFICATIONS.index(test_ttp.portion_marking)
          render json: {errors: ["Invalid Classification, Classification of the Indicator is less than the classification of the contained TTP objects"]}, status: 403
          return
        end
        
      end
      @indicator.ttp_stix_ids = params[:ttp_stix_ids] || []
    end

    Audit.justification = params[:justification] if params[:justification]
    @indicator.update_attributes(indicator_params)

    validation_errors = {:base => []}

    if @indicator.errors.present?
      validation_errors[:base] << @indicator.errors.messages
    end

    # Look through all the ttps and find errors. Add them to the errors array.
    @indicator.ttps.each do |its|
      if its.errors.messages.present? && its.errors.messages[:base].present?
        its.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    if validation_errors[:base].blank?
      update_kill_chains(params[:kill_chain_phases])
      @indicator.reload
      render(json: @indicator) && return
    else
      render json: {errors: @indicator.errors}, status: :unprocessable_entity
    end
  end

  def destroy
    @indicator = Indicator.find_by_stix_id(params[:id])
    if !Permissions.can_be_deleted_by(current_user, @indicator)
      render json: {errors: ["You do not have the ability to delete indicators"]}, status: 403
      return
    end
    if @indicator.destroy
      head 204
    else
      render json: {errors:["Indicator could not be deleted"] },status: :unprocessable_entity
    end
  end

  def bulk_tags
    # Make sure we only get the params that were expecting
    params.permit(:ind_stix_ids, :user_tag_ids, :system_tag_ids)

    # keep track of how many indicators we have updated.
    amount_user = 0
    amount_sys = 0

    # For each indicator that we get we need to add the tags to it if it doesnt exist.
    params[:ind_stix_ids].each do |e|
      @indicator = Indicator.find_by_stix_id(e)

      if params[:user_tag_ids].present?
        if !User.has_permission(current_user,'tag_item_with_user_tag')
          render json: {errors: ["You do not have the ability to update user tags"]}, status: 403
          return
        end

        # subtract the params array of guids from the existing ones so we dont get dups.
        to_add_tags = params[:user_tag_ids] - @indicator.user_tag_ids

        # check if theirs anything new to add to the array of system tags
        if to_add_tags.present?
          @indicator.update_user_tag_guids(current_user, to_add_tags)
          amount_user += 1
        end
      end

      if params[:system_tag_ids].present?
        if !User.has_permission(current_user,'tag_item_with_system_tag')
          render json: {errors: ["You do not have the ability to update system tags"]}, status: 403
          return
        end

        # subtract the params array of guids from the existing ones so we dont get dups.
        to_add_tags = params[:system_tag_ids] - @indicator.system_tag_ids
        
        # check if theirs anything new to add to the array of system tags
        if to_add_tags.present?
          @indicator.system_tag_guids = @indicator.system_tag_ids.concat(to_add_tags);
          amount_sys += 1
        end
      end
      
      if @indicator.valid?
      else
        render json: {errors: @indicator.errors}, status: :unprocessable_entity
      end
    end

    # build the toastr message that will be rendered 
    success_string = "Successfully Added "
    success_string += "User Tags to " + amount_user.to_s + "/" + params[:ind_stix_ids].count.to_s + " Indicators. " if params[:user_tag_ids].count > 0
    success_string += "System Tags to " + amount_sys.to_s + "/" + params[:ind_stix_ids].count.to_s + " Indicators. " if params[:system_tag_ids].count > 0

    render json: {base: success_string}
  end

  def coa_additions
    # Make sure we only get the params that were expecting
    params.permit(:indicator_stix_id, :coa_stix_ids)

    @indicator = Indicator.find_by_stix_id(params[:indicator_stix_id])

    if params[:coa_stix_ids].present?
      if !User.has_permission(current_user,'link_indicators_to_course_of_actions')
        render json: {errors: ["You do not have the ability to link Indicators to Courses of Action"]}, status: 403
        return
      end

      # subtract the params array of stix_ids from the existing ones so we dont get dups.
      to_add_coas = params[:coa_stix_ids] - @indicator.course_of_action_ids

      # check if theirs anything new to add to the array of Coa IDs
      if to_add_coas.present?
        to_add_coas.each do |id_to_be_linked|
          obj = CourseOfAction.find_by_stix_id(id_to_be_linked)
          if obj.present? && @indicator.portion_marking.present? && obj.portion_marking.present? && Classification::CLASSIFICATIONS.index(@indicator.portion_marking) < Classification::CLASSIFICATIONS.index(obj.portion_marking)
            render json: {errors: ["Invalid Classification, Classification of the Indicator is less than the classification of the contained COA objects"]}, status: 403
            return
          end
        end

        @indicator.course_of_action_stix_ids = @indicator.course_of_action_ids.concat(to_add_coas);
      end
    end
    
    if @indicator.valid?
      @indicator.reload
      render(json: @indicator) && return
    else
      render json: {errors: @indicator.errors}, status: :unprocessable_entity
    end
  end

  def related_by_cbx_indicators
    # only permit the indicator stix ids
    params.permit(:indicator_stix_ids, :limit)

    # get a list of cybox object id's so we can query against the observables
    cybox_object_ids = Indicator.where(stix_id: params[:indicator_stix_ids]).joins(:observables).collect(&:observables).flatten.collect(&:remote_object_id).uniq

    # get the list of indicators from observables with indicators matching from our list of cybox object ids without the original ones already linked
    @indicators = Observable.where(remote_object_id: cybox_object_ids).joins(:indicator).where.not(stix_indicator_id: params[:indicator_stix_ids]).collect(&:indicator)

    @indicators = @indicators.select{|i| Classification::CLASSIFICATIONS.index(i.portion_marking) >= Classification::CLASSIFICATIONS.index(params[:limit])} if params[:limit] && Classification::CLASSIFICATIONS.include?(params[:limit])

    @metadata = Metadata.new
    @metadata.total_count = @indicators.count
   
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, indicators: @indicators} }
    end
  end

private

  def indicator_params
    params[:observables] ||= []
    params[:ttp_stix_ids] ||= []

    params.permit(:stix_id,
                  :title,
                  :indicator_type,
                  :description,
                  :reference,
                  :downgrade_request_id,
                  :dms_label,
                  :acs_set_id,
                  :alternative_id,
                  :timelines,
                  :source_of_report,
                  :target_of_attack,
                  :target_scope,
                  :actor_attribution,
                  :actor_type,
                  :modus_operandi,
                  :start_time,
                  :end_time,
                  :start_time_precision,
                  :end_time_precision,
                  STIX_MARKING_PERMITTED_PARAMS,
                  :confidences_attributes => [:value,:is_official,:description, :source],
                  :observables => [],
                  :ttp_stix_ids => []
    )
  end

  def update_kill_chains(phases)
    ph = []
    if phases
      phases.each do |p|
        if p.class.to_s == "String"
          k=KillChainPhase.find_by_stix_kill_chain_phase_id(p)
          ph << k if k.present?
        else
          ph << p[:id]
        end
      end
    end
    remove_list=[]
    add_list=[]
    i = @indicator.kill_chain_phases.map{|x| x.id}
    # Delete unneeded phases
    @indicator.kill_chain_phases.each do |kcp|
      unless ph.include? kcp.id
        @indicator.kill_chain_phases.delete(kcp)
        remove_list << kcp.phase_name
      end
    end
    # Add in new ones
    ph.each do |pp|
      unless i.include? pp
        p=KillChainPhase.find(pp)
        @indicator.kill_chain_phases << p
        add_list << p.phase_name
      end
    end
    if add_list.length>0 or remove_list.length>0
      audit = Audit.basic
      audit.item = @indicator
      audit.audit_type = :kill_chains
      audit.message = ""
      audit.message += "Removed: #{remove_list.join(', ')}" if remove_list.length>0
      audit.message += ", " if audit.message.length>0
      audit.message += "Added: #{add_list.join(', ')}" if add_list.length>0
      audit.user = current_user
      @indicator.audits << audit
    end
  end
end
