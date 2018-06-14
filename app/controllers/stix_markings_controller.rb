class StixMarkingsController < ApplicationController
  before_filter :isa_params, only: [:create,:update]

  def index
    # Preprocess wildcards
    unless params.nil?
      params.each_value do |value|
        unless value.nil? or !value.is_a? String
          value.tr!('*', '%')
          value.tr!('?', '_')
        end
      end
    end

    @stix_markings = StixMarking.where({stix_id: params[:ids]}) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    params[:created_at_ebt] = params[:created_at_ebt].to_date.beginning_of_day if params[:created_at_ebt].present?
    params[:created_at_iet] = params[:created_at_iet].to_date.end_of_day if params[:created_at_iet].present?
    params[:updated_at_ebt] = params[:updated_at_ebt].to_date.beginning_of_day if params[:updated_at_ebt].present?
    params[:updated_at_iet] = params[:updated_at_iet].to_date.end_of_day if params[:updated_at_iet].present?
    params[:classified_on_ebt] = params[:classified_on_ebt].to_date.beginning_of_day if params[:classified_on_ebt].present?
    params[:classified_on_iet] = params[:classified_on_iet].to_date.end_of_day if params[:classified_on_iet].present?
    params[:public_released_on_ebt] = params[:public_released_on_ebt].to_date.beginning_of_day if params[:public_released_on_ebt].present?
    params[:public_released_on_iet] = params[:public_released_on_iet].to_date.end_of_day if params[:public_released_on_iet].present?

    @stix_markings ||= StixMarking.all.reorder(created_at: :desc)
    
    # Special Restrictions
    
    # Addresses need to be limited to IP addresses
    if (params[:remote_object_type].present? && params[:remote_object_type] == 'Address')
      @stix_markings = @stix_markings.joins("LEFT JOIN cybox_addresses ON stix_markings.remote_object_id = cybox_addresses.guid")
        .where("cybox_addresses.category in ('ipv4-addr','ipv6-addr')")
    end

    # Search fields that occur in multiple contexts
    if params[:guid].present?
      # NOTE: Adding searching for the GUID on ISA Privs or Further Sharings can cause cross 
      # products where multiple versions of each result come back
      @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_marking_structures ON stix_markings.stix_id = isa_marking_structures.stix_marking_id")
        .joins("LEFT JOIN ais_consent_marking_structures ON stix_markings.stix_id = ais_consent_marking_structures.stix_marking_id")
        .joins("LEFT JOIN tlp_structures ON stix_markings.stix_id = tlp_structures.stix_marking_id")
        .where("lower(stix_markings.guid) like (:guid) 
             OR lower(isa_assertion_structures.guid) like (:guid)
             OR lower(isa_marking_structures.guid) like (:guid)
             OR lower(ais_consent_marking_structures.guid) like (:guid)
             OR lower(tlp_structures.guid) like (:guid)", 
             {guid: params[:guid].downcase})
    end
    if params[:stix_id].present?
      @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_marking_structures ON stix_markings.stix_id = isa_marking_structures.stix_marking_id")
        .joins("LEFT JOIN ais_consent_marking_structures ON stix_markings.stix_id = ais_consent_marking_structures.stix_marking_id")
        .joins("LEFT JOIN tlp_structures ON stix_markings.stix_id = tlp_structures.stix_marking_id")
        .where("lower(stix_markings.stix_id) like (:stix_id) 
             OR lower(isa_assertion_structures.stix_id) like (:stix_id)
             OR lower(isa_marking_structures.stix_id) like (:stix_id)
             OR lower(ais_consent_marking_structures.stix_id) like (:stix_id)
             OR lower(tlp_structures.stix_id) like (:stix_id)", 
             {stix_id: params[:stix_id].downcase})
    end
    if params[:color].present?
      if params[:color].downcase == 'white'
        # User has searched for color 'white', we also need to search for the ISA
        # equivalent determination of 'PUBREL'
        @stix_markings = @stix_markings.joins("LEFT JOIN ais_consent_marking_structures ON stix_markings.stix_id = ais_consent_marking_structures.stix_marking_id")
          .joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
          .joins("LEFT JOIN tlp_structures ON stix_markings.stix_id = tlp_structures.stix_marking_id")
          .where("ais_consent_marking_structures.color like 'white'
               OR tlp_structures.color like 'white'
               OR isa_assertion_structures.cs_formal_determination like '%PUBREL%'")
      else
        @stix_markings = @stix_markings.joins("LEFT JOIN ais_consent_marking_structures ON stix_markings.stix_id = ais_consent_marking_structures.stix_marking_id")
          .joins("LEFT JOIN tlp_structures ON stix_markings.stix_id = tlp_structures.stix_marking_id")
          .where("ais_consent_marking_structures.color like (:color)
               OR tlp_structures.color like (:color)",
              {color: params[:color].downcase})
      end
    end
    if params[:cs_formal_determination].present?
      if params[:cs_formal_determination].downcase == 'pubrel'
        # User has searched for determination 'pubrel', we also need to search for the AIS
        # equivalent color of 'white'
        @stix_markings = @stix_markings.joins("LEFT JOIN ais_consent_marking_structures ON stix_markings.stix_id = ais_consent_marking_structures.stix_marking_id")
          .joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
          .joins("LEFT JOIN tlp_structures ON stix_markings.stix_id = tlp_structures.stix_marking_id")
          .where("ais_consent_marking_structures.color like 'white'
               OR tlp_structures.color like 'white'
               OR isa_assertion_structures.cs_formal_determination like '%PUBREL%'")
      else
        @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
            .where('isa_assertion_structures.cs_formal_determination like (?)',  
              params[:cs_formal_determination].upcase)
      end
    end

    # Search top level STIX Markings
    if params[:remote_object_id].present?
      @stix_markings = @stix_markings.where('lower(stix_markings.remote_object_id) like (?)',
          params[:remote_object_id].downcase)
    else
      @stix_markings = @stix_markings.where('stix_markings.remote_object_id is not null')
    end 
    if params[:remote_object_type].present?
      @stix_markings = @stix_markings.where('lower(stix_markings.remote_object_type) like (?)',
          params[:remote_object_type].downcase)
    end 
    @stix_markings = @stix_markings.where('stix_markings.created_at'=>  
        params[:created_at_ebt]..params[:created_at_iet]) if params[:created_at_ebt].present? && params[:created_at_iet].present?
    @stix_markings = @stix_markings.where('stix_markings.updated_at'=>  
        params[:updated_at_ebt]..params[:updated_at_iet]) if params[:updated_at_ebt].present? && params[:updated_at_iet].present?
    @stix_markings = @stix_markings.where('stix_markings.remote_object_field like (?)',
        params[:remote_object_field].downcase) if params[:remote_object_field].present?
    @stix_markings = @stix_markings.where('lower(stix_markings.controlled_structure) like (?)',
        params[:controlled_structure].downcase) if params[:controlled_structure].present?
        
    # Search ISA Assertion Structures  
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('isa_assertion_structures.cs_classification like (?)', 
          params[:cs_classification].upcase) if params[:cs_classification].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('isa_assertion_structures.cs_countries like (?)', 
          params[:cs_countries].upcase) if params[:cs_countries].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('isa_assertion_structures.cs_cui like (?)',  
          params[:cs_cui].upcase) if params[:cs_cui].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('isa_assertion_structures.cs_entity like (?)',  
          params[:cs_entity].upcase) if params[:cs_entity].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('isa_assertion_structures.cs_orgs like (?)',  
          params[:cs_orgs].upcase) if params[:cs_orgs].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('isa_assertion_structures.cs_shargrp like (?)',  
          params[:cs_shargrp].upcase) if params[:cs_shargrp].present?
    if params[:is_default_marking].present?
      if ['t', 'true'].include?(params[:is_default_marking].downcase)
        @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
            .where('isa_assertion_structures.is_default_marking' => true)
      elsif ['f', 'false'].include?(params[:is_default_marking].downcase)
        @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
            .where('isa_assertion_structures.is_default_marking' => false)
      end
    end 
    if params[:public_release].present?
      if ['t', 'true'].include?(params[:public_release].downcase)
        @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
            .where('isa_assertion_structures.public_release' => true)
      elsif ['f', 'false'].include?(params[:public_release].downcase)
        @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
            .where('isa_assertion_structures.public_release' => false)
      end
    end
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('lower(isa_assertion_structures.public_released_by) like (?)',  
          params[:public_released_by].downcase) if params[:public_released_by].present?
    @stix_markings = @stix_markings.joins(:isa_assertion_structure)
        .where('isa_assertion_structures.public_released_on' =>
          params[:public_released_on_ebt]..params[:public_released_on_iet]) if params[:public_released_on_ebt].present? && params[:public_released_on_iet].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('isa_assertion_structures.cs_info_caveat like (?)',  
          params[:cs_info_caveat].upcase) if params[:cs_info_caveat].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('lower(isa_assertion_structures.classified_by) like (?)',  
          params[:classified_by].downcase) if params[:classified_by].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('isa_assertion_structures.classified_on'=>  
          params[:classified_on_ebt]..params[:classified_on_iet]) if params[:classified_on_ebt].present? && params[:classified_on_iet].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where('lower(isa_assertion_structures.classification_reason) like (?)',  
          params[:classification_reason].downcase) if params[:classification_reason].present?

    # ISA Priv Searching
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'DSPLY').where('isa_privs.effect' => params[:dsply].downcase) if params[:dsply].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'IDSRC').where('isa_privs.effect' => params[:idsrc].downcase) if params[:idsrc].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'TENOT').where('isa_privs.effect' => params[:tenot].downcase) if params[:tenot].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'NETDEF').where('isa_privs.effect' => params[:netdef].downcase) if params[:netdef].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'LEGAL').where('isa_privs.effect' => params[:legal].downcase) if params[:legal].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'INTEL').where('isa_privs.effect' => params[:intel].downcase) if params[:intel].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'TEARLINE').where('isa_privs.effect' => params[:tearline].downcase) if params[:tearline].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'OPACTION').where('isa_privs.effect' => params[:opaction].downcase) if params[:opaction].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'REQUEST').where('isa_privs.effect' => params[:request].downcase) if params[:request].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'ANONYMOUSACCESS').where('isa_privs.effect' => params[:anonymousaccess].downcase) if params[:anonymousaccess].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        .where('isa_privs.action' => 'CISAUSES').where('isa_privs.effect' => params[:cisauses].downcase) if params[:cisauses].present?

    # Further Sharing Search
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN further_sharings ON isa_assertion_structures.guid = further_sharings.isa_assertion_structure_guid")
        .where("lower(further_sharings.scope) like (?)", params[:scope].downcase) if params[:scope].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("LEFT JOIN further_sharings ON isa_assertion_structures.guid = further_sharings.isa_assertion_structure_guid")
        .where("lower(further_sharings.effect) like (?)", params[:effect].downcase) if params[:effect].present?

    #ISA Marking Structure Search
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_marking_structures ON stix_markings.stix_id = isa_marking_structures.stix_marking_id")
        .where("lower(isa_marking_structures.re_custodian) like (?)", params[:re_custodian].downcase) if params[:re_custodian].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN isa_marking_structures ON stix_markings.stix_id = isa_marking_structures.stix_marking_id")
        .where("lower(isa_marking_structures.re_originator) like (?)", params[:re_originator].downcase) if params[:re_originator].present?
        
    # AIS Consent Marking Structure Search
    @stix_markings = @stix_markings.joins("LEFT JOIN ais_consent_marking_structures ON stix_markings.stix_id = ais_consent_marking_structures.stix_marking_id")
        .where("lower(ais_consent_marking_structures.consent) like (?)", params[:consent].downcase) if params[:consent].present?
    if params[:proprietary].present?
      if ['t', 'true'].include?(params[:proprietary].downcase)
        @stix_markings = @stix_markings.joins("LEFT JOIN ais_consent_marking_structures ON stix_markings.stix_id = ais_consent_marking_structures.stix_marking_id")
            .where('ais_consent_marking_structures.proprietary' => true)
      elsif ['f', 'false'].include?(params[:proprietary].downcase)
        @stix_markings = @stix_markings.joins("LEFT JOIN ais_consent_marking_structures ON stix_markings.stix_id = ais_consent_marking_structures.stix_marking_id")
            .where('ais_consent_marking_structures.proprietary' => false)
      end
    end
    
    # Contributing Sources Search
    @stix_markings = @stix_markings.joins("LEFT JOIN stix_packages ON stix_markings.remote_object_id = stix_packages.guid")
        .joins("LEFT JOIN contributing_sources ON stix_packages.stix_id = contributing_sources.stix_package_stix_id")
        .where("stix_markings.remote_object_type = 'StixPackage'")
        .where("lower(contributing_sources.organization_names) like (?)", params[:organization_names].downcase) if params[:organization_names].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN stix_packages ON stix_markings.remote_object_id = stix_packages.guid")
        .joins("LEFT JOIN contributing_sources ON stix_packages.stix_id = contributing_sources.stix_package_stix_id")
        .where("stix_markings.remote_object_type = 'StixPackage'")
        .where("lower(contributing_sources.countries) like (?)", params[:countries].downcase) if params[:countries].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN stix_packages ON stix_markings.remote_object_id = stix_packages.guid")
        .joins("LEFT JOIN contributing_sources ON stix_packages.stix_id = contributing_sources.stix_package_stix_id")
        .where("stix_markings.remote_object_type = 'StixPackage'")
        .where("lower(contributing_sources.administrative_areas) like (?)", params[:administrative_areas].downcase) if params[:administrative_areas].present?
    @stix_markings = @stix_markings.joins("LEFT JOIN stix_packages ON stix_markings.remote_object_id = stix_packages.guid")
        .joins("LEFT JOIN contributing_sources ON stix_packages.stix_id = contributing_sources.stix_package_stix_id")
        .where("stix_markings.remote_object_type = 'StixPackage'")
        .where("lower(contributing_sources.organization_info) like (?)", params[:organization_info].downcase) if params[:organization_info].present?
    if params[:is_federal].present?
      if ['t', 'true'].include?(params[:is_federal].downcase)
        @stix_markings = @stix_markings.joins("LEFT JOIN stix_packages ON stix_markings.remote_object_id = stix_packages.guid")
            .joins("LEFT JOIN contributing_sources ON stix_packages.stix_id = contributing_sources.stix_package_stix_id")
            .where("stix_markings.remote_object_type = 'StixPackage'")
            .where('contributing_sources.is_federal' => true)
      elsif ['f', 'false'].include?(params[:is_federal].downcase)
        @stix_markings = @stix_markings.joins("LEFT JOIN stix_packages ON stix_markings.remote_object_id = stix_packages.guid")
            .joins("LEFT JOIN contributing_sources ON stix_packages.stix_id = contributing_sources.stix_package_stix_id")
            .where("stix_markings.remote_object_type = 'StixPackage'")
            .where('contributing_sources.is_federal' => false)
      end        
    end
        
    @stix_markings = apply_sort(@stix_markings, params)
    total_count = @stix_markings.count
    @stix_markings = @stix_markings.limit(limit).offset(offset)
    
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    # Convert to return_type (Type conversion functionality has been removed)
    @result_objects = @stix_markings
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, result_objects: @result_objects} }
      format.csv { render "stix_markings/index.csv.erb" }
    end
  end

  def show
    @stix_marking = StixMarking.includes(
        audits: :user
    ).find_by_stix_id(params[:id])
      
    if @stix_marking
      render json: @stix_marking
    else
      render json: {errors: ["Invalid stix marking record number"]}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'modify_all_items')
      render json: {errors: ["You do not have the ability to create stix markings"]}, status: 403
      return
    end

    @stix_marking = StixMarking.create(stix_marking_params)
    if @stix_marking.errors.blank?
      render(json: @stix_marking)
      return
    else
      render json: {errors: @stix_marking.errors}, status: :unprocessable_entity
    end
  end

  def update
    @stix_marking = StixMarking.find_by_stix_id(params[:id])

    unless Permissions.can_be_modified_by(current_user, @stix_marking)
      render json: {errors: ["You do not have the ability to modify this stix marking"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @stix_marking.update(stix_marking_params)

    if @stix_marking.errors.blank?
      render(json: @stix_marking)
      return
    else
      render json: {errors: @stix_marking.errors}, status: :unprocessable_entity
    end
  end

  def destroy
    @stix_marking = StixMarking.find_by_stix_id(params[:id])
    if !User.has_permission(current_user, 'delete_all_items') || !Permissions.can_be_deleted_by(current_user, @stix_marking)
      render json: {errors: ["You do not have the ability to delete markings"]}, status: 403
      return
    end
    if @stix_marking.present? && @stix_marking.destroy
      head 204
    else
      if @stix_marking.blank?
        render json: {errors: {:StixMarking => "not found."} }, status: :unprocessable_entity
      else
        render json: {errors: {} },status: :unprocessable_entity
      end
    end
  end

  def isa_params
    return unless params[:isa_assertion_structure_attributes].present?
    params[:isa_assertion_structure_attributes].each do |iasa|
      # for some reason this doesnt store it in the original params unless you do it
      # like this...
      if iasa[0].include?("cs_") && iasa[1].is_a?(Array)
        params[:isa_assertion_structure_attributes][:"#{iasa[0]}"] = iasa[1].join(",")
      end
    end
  end

private
  
  def stix_marking_params
    params.permit(
      :stix_id,
      :controlled_structure,
      :remote_object_type,
      :remote_object_id,
      :remote_object_field,
      :_destroy,
      :tlp_marking_structure_attributes => [
          :id,
          :color,
          :_destroy
      ],
      :isa_assertion_structure_attributes => [
          :id,
          :public_release,
          :cs_countries,
          :cs_orgs,
          :cs_entity,
          :cs_cui,
          :cs_shargrp,
          :re_custodian,
          :re_originator,
          :cs_formal_determination,
          :public_released_by,
          :public_released_on,
          :re_data_item_created_at,
          :cs_classification,
          :classified_by,
          :classified_on,
          :classification_reason,
          :privilege_default,
          :_destroy,
          :isa_privs_attributes => [
              :id,
              :action,
              :effect,
              :scope_countries,
              :scope_entity,
              :scope_is_all,
              :scope_orgs,
              :scope_shargrp,
              :_destroy
          ],
          :further_sharings_attributes => [
            :scope,
            :effect,
            :id,
            :_destroy
          ]
      ],
      :isa_marking_structure_attributes => [
          :id,
          :data_item_created_at,
          :re_custodian,
          :re_originator,
          :_destroy
      ]
    )
  end

end
