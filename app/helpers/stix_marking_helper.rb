module StixMarkingHelper

  def get_markings_for_stix_xml(obj)
    return [] unless obj.present? && obj.respond_to?(:stix_markings)

    case obj.class.to_s
      when 'Address'
        markings = get_markings(obj)
      when 'CourseOfAction'
        markings = get_coa_markings(obj)
      when 'CyboxFile'
        markings = get_cybox_file_markings(obj)
      when 'CyboxMutex'
        markings = get_markings(obj)
      when 'DnsRecord'
        markings = get_markings(obj)
      when 'Domain'
        markings = get_markings(obj)
      when 'EmailMessage'
        markings = get_email_message_markings(obj)
      when 'ExploitTarget'
        markings = get_et_markings(obj)
      when 'Hostname'
        markings = get_markings(obj)
      when 'HttpSession'
        markings = get_markings(obj)
      when 'Indicator'
        markings = get_indicator_markings(obj)
      when 'Link'
        markings = get_link_markings(obj)
      when 'NetworkConnection'
        markings = get_markings(obj)
      when 'Registry'
        markings = get_registry_markings(obj)
      when 'Ttp'
        markings = get_ttp_markings(obj)
      when 'StixPackage'
        markings = get_stix_package_markings(obj)
      when 'Uri'
        markings = get_markings(obj)
      else
        markings = get_markings(obj)
    end

    markings
  end

  def get_markings(obj)
    markings = []
    markings.concat(obj.stix_markings) if obj.present? &&
        obj.stix_markings.present?

    markings
  end

  def get_coa_markings(obj)
    markings = get_markings(obj)

    if obj.acs_set.present? && obj.acs_set.stix_markings.present?
      acs_set_markings = obj.acs_set.stix_markings.collect { |m|
        m.controlled_structure =
            "//stix:Course_Of_Action[@id='#{obj.stix_id}']/" +
                'descendant-or-self::node()'
        m.controlled_structure += " | #{m.controlled_structure}/@*"
        m
      }
      markings.concat(acs_set_markings) if acs_set_markings.present?
    end

    markings
  end

  def get_cybox_file_markings(obj)
    markings = get_markings(obj)

    if obj.file_hashes.present?
      file_hash_markings =
          obj.file_hashes.collect { |fh| get_markings(fh) }.flatten
      markings.concat(file_hash_markings) if file_hash_markings.present?
    end

    markings
  end

  def get_email_message_markings(obj)
    markings = get_markings(obj)

    if obj.links.present?
      link_markings = obj.links.collect { |l| get_link_markings(l) }.flatten
      markings.concat(link_markings) if link_markings.present?
    end

    if obj.uris.present?
      uri_markings = obj.uris.collect { |u| get_markings(u) }.flatten
      markings.concat(uri_markings) if uri_markings.present?
    end

    if obj.cybox_files.present?
      cybox_file_markings =
          obj.cybox_files.collect { |u| get_cybox_file_markings(u) }.flatten
      markings.concat(cybox_file_markings) if cybox_file_markings.present?
    end

    markings
  end

  def get_et_markings(obj)
    # Base vulnerability controlled structures off this exploit target.
    obj.set_vulnerability_controlled_structures

    markings = get_markings(obj)

    if obj.acs_set.present? && obj.acs_set.stix_markings.present?
      acs_set_markings = obj.acs_set.stix_markings.collect { |m|
        m.controlled_structure =
            "//stixCommon:Exploit_Target[@id='#{obj.stix_id}']/" +
                'descendant-or-self::node()'
        m.controlled_structure += " | #{m.controlled_structure}/@*"
        m
      }
      markings.concat(acs_set_markings) if acs_set_markings.present?
    end

    if obj.vulnerabilities.present?
      vulnerability_markings =
          obj.vulnerabilities.collect { |v| get_markings(v) }.flatten
      markings.concat(vulnerability_markings) if vulnerability_markings.
          present?
    end

    markings
  end

  def get_ttp_markings(obj)
    # Base attack pattern controlled structures off this TTP.
    obj.set_ap_controlled_structures

    markings = get_markings(obj)

    if obj.acs_set.present? && obj.acs_set.stix_markings.present?
      acs_set_markings = obj.acs_set.stix_markings.collect { |m|
        m.controlled_structure =
            "//stix:TTP[@id='#{obj.stix_id}']/" +
                'descendant-or-self::node()'
        m.controlled_structure += " | #{m.controlled_structure}/@*"
        m
      }
      markings.concat(acs_set_markings) if acs_set_markings.present?
    end

    if obj.attack_patterns.present?
      ap_markings =
          obj.attack_patterns.collect { |v| get_markings(v) }.flatten
      markings.concat(ap_markings) if ap_markings.present?
    end

    markings
  end

  def get_indicator_markings(obj)
    markings = get_markings(obj)

    if obj.acs_set.present? && obj.acs_set.stix_markings.present?
      acs_set_markings = obj.acs_set.stix_markings.collect { |m|
        m.controlled_structure =
            "//stix:Indicator[@id='#{obj.stix_id}']/" +
                'descendant-or-self::node()'
        m.controlled_structure += " | #{m.controlled_structure}/@*"
        m
      }
      markings.concat(acs_set_markings) if acs_set_markings.present?
    end

    markings
  end

  def get_link_markings(obj)
    markings = get_markings(obj)

    if obj.uri.present? && obj.uri.stix_markings.present?
      uri_markings = obj.uri.stix_markings.collect { |m|
        m.controlled_structure =
            "//cybox:Object[@id='#{obj.cybox_object_id}']/" +
                'cybox:Properties/URIObj:Value/descendant-or-self::node()'
        m.controlled_structure += " | #{m.controlled_structure}/@*"
        m
      }
      markings.concat(uri_markings) if uri_markings.present?
    end

    markings
  end

  def get_registry_markings(obj)
    markings = get_markings(obj)

    if obj.registry_values.present?
      registry_value_markings =
          obj.registry_values.collect { |rv| get_markings(rv) }.flatten
      markings.concat(registry_value_markings) if registry_value_markings.
          present?
    end

    markings
  end


  def get_stix_package_markings(obj)
    markings = get_markings(obj)

    if obj.acs_set.present? && obj.acs_set.stix_markings.present?
      acs_set_markings = obj.acs_set.stix_markings.collect { |m|
        m.controlled_structure =
            "//stix:STIX_Package[@id='#{obj.stix_id}']/" +
                'descendant-or-self::node()'
        m.controlled_structure += " | #{m.controlled_structure}/@*"
        m
      }
      markings.concat(acs_set_markings) if acs_set_markings.present?
    end

    markings
  end

  def collect_object_markings(observables)
    return nil unless observables.present?

    object_markings = observables.select { |o|
      o.object.respond_to?(:stix_markings) }.collect { |o|
      get_markings_for_stix_xml(o.object) }.flatten

    object_markings.present? ?
        object_markings.reject { |m| m.controlled_structure.blank? }.uniq : nil
  end

  def reject_markings_of_blank_things(markings)
    return markings unless markings.present?

    markings.reject { |m| m.remote_object.blank? ||
        (m.remote_object_field.present? &&
            m.remote_object[m.remote_object_field.to_sym].blank?) }
  end
  
  def add_stix_markings_constraints(query_obj, search_params)
    # Preprocess wildcards
    unless search_params.nil?
      search_params.each_value do |value|
        unless value.nil? or !value.is_a? String
          value.tr!('*', '%')
          value.tr!('?', '_')
        end
      end
    end
    
    isa_equiv_search = false
    if (search_params['ais_color'].present? and search_params['ais_color'].downcase == 'white') or
       (search_params['tlp_color'].present? and search_params['tlp_color'].downcase == 'white') or
       (search_params['cs_formal_determination'].present? and search_params['cs_formal_determination'].downcase == 'pubrel')

      isa_equiv_search = true
      # Perform ISA Equivalence searching
      query_obj = query_obj.joins("LEFT JOIN ais_consent_marking_structures ON stix_markings.stix_id = ais_consent_marking_structures.stix_marking_id")
        .joins("LEFT JOIN tlp_structures ON stix_markings.stix_id = tlp_structures.stix_marking_id")
        .joins("LEFT JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .where("lower(ais_consent_marking_structures.color) = 'white' or lower(tlp_structures.color) = 'white' or lower(isa_assertion_structures.cs_formal_determination) like '%pubrel%'")
    end

    # Prepare date fields
    search_params['created_at_ebt'] = search_params['created_at_ebt'].to_date.beginning_of_day if search_params['created_at_ebt'].present?
    search_params['created_at_iet'] = search_params['created_at_iet'].to_date.end_of_day if search_params['created_at_iet'].present?
    search_params['updated_at_ebt'] = search_params['updated_at_ebt'].to_date.beginning_of_day if search_params['updated_at_ebt'].present?
    search_params['updated_at_iet'] = search_params['updated_at_iet'].to_date.end_of_day if search_params['updated_at_iet'].present?
    search_params['classified_on_ebt'] = search_params['classified_on_ebt'].to_date.beginning_of_day if search_params['classified_on_ebt'].present?
    search_params['classified_on_iet'] = search_params['classified_on_iet'].to_date.end_of_day if search_params['classified_on_iet'].present?
    search_params['public_released_on_ebt'] = search_params['public_released_on_ebt'].to_date.beginning_of_day if search_params['public_released_on_ebt'].present?
    search_params['public_released_on_iet'] = search_params['public_released_on_iet'].to_date.end_of_day if search_params['public_released_on_iet'].present?
    
    # Search top level STIX Markings
    query_obj = query_obj.where('lower(stix_markings.remote_object_id) like (?)', 
      search_params['remote_object_id'].downcase) if search_params['remote_object_id'].present?
    query_obj = query_obj.where('stix_markings.created_at'=>  
      search_params['created_at_ebt']..search_params['created_at_iet']) if search_params['created_at_ebt'].present? && search_params['created_at_iet'].present?
    query_obj = query_obj.where('stix_markings.updated_at'=>  
      search_params['updated_at_ebt']..search_params['updated_at_iet']) if search_params['updated_at_ebt'].present? && search_params['updated_at_iet'].present?
    query_obj = query_obj.where('stix_markings.remote_object_field like (?)',
      search_params['remote_object_field'].downcase) if search_params['remote_object_field'].present?
    query_obj = query_obj.where('lower(stix_markings.controlled_structure) like (?)',
      search_params['controlled_structure'].downcase) if search_params['controlled_structure'].present?
          
    # Search ISA Assertion Structures
    if ['cs_classification', 'cs_countries', 'cs_cui', 'cs_entity', 'cs_orgs', 'cs_shargrp',
        'cs_formal_determination', 'public_release', 'public_released_by', 'public_released_on_ebt',
        'public_released_on_iet', 'classified_by', 'classified_on_ebt', 'classified_on_iet',
        'classification_reason'].any? {|k| search_params.key?(k)}
        
      if !isa_equiv_search
        query_obj = query_obj.joins("JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
      end
      
      query_obj = query_obj.where('isa_assertion_structures.cs_classification like (?)', 
          search_params['cs_classification'].upcase) if search_params['cs_classification'].present?
      query_obj = query_obj.where("instr(','||isa_assertion_structures.cs_countries||',', ','||?||',')>0", 
          search_params['cs_countries'].upcase) if search_params['cs_countries'].present?
      query_obj = query_obj.where("instr(','||isa_assertion_structures.cs_cui||',', ','||?||',')>0",  
          search_params['cs_cui'].upcase) if search_params['cs_cui'].present?
      query_obj = query_obj.where("instr(','||isa_assertion_structures.cs_entity||',', ','||?||',')>0",  
          search_params['cs_entity'].upcase) if search_params['cs_entity'].present?
      query_obj = query_obj.where("instr(','||isa_assertion_structures.cs_orgs||',', ','||?||',')>0",  
          search_params['cs_orgs'].upcase) if search_params['cs_orgs'].present?
      query_obj = query_obj.where("instr(','||isa_assertion_structures.cs_shargrp||',', ','||?||',')>0",  
          search_params['cs_shargrp'].upcase) if search_params['cs_shargrp'].present?
      if search_params['cs_formal_determination'].present? and search_params['cs_formal_determination'].downcase != 'pubrel'
        query_obj = query_obj.where("instr(','||isa_assertion_structures.cs_formal_determination||',', ','||?||',')>0",  
            search_params['cs_formal_determination'].upcase)
      end 
      if search_params['public_release'].present?
        if ['t', 'true'].include?(search_params['public_release'].downcase)
          query_obj = query_obj.where('isa_assertion_structures.public_release' => true)
        elsif ['f', 'false'].include?(search_params['public_release'].downcase)
          query_obj = query_obj.where('isa_assertion_structures.public_release' => false)
        end
      end
      query_obj = query_obj.where('lower(isa_assertion_structures.public_released_by) like (?)',  
          search_params['public_released_by'].downcase) if search_params['public_released_by'].present?
      query_obj = query_obj.where('isa_assertion_structures.public_released_on' =>
          search_params['public_released_on_ebt']..search_params['public_released_on_iet']) if search_params['public_released_on_ebt'].present? && search_params['public_released_on_iet'].present?
      query_obj = query_obj.where('lower(isa_assertion_structures.classified_by) like (?)',  
          search_params['classified_by'].downcase) if search_params['classified_by'].present?
      query_obj = query_obj.where('isa_assertion_structures.classified_on'=>  
          search_params['classified_on_ebt']..search_params['classified_on_iet']) if search_params['classified_on_ebt'].present? && search_params['classified_on_iet'].present?
      query_obj = query_obj.where('lower(isa_assertion_structures.classification_reason) like (?)',  
          search_params['classification_reason'].downcase) if search_params['classification_reason'].present?
    end
    
    # ISA Priv Searching
    if ['dsply', 'idsrc', 'tenot', 'netdef', 'legal', 'intel', 'tearline', 'opaction', 'request',
        'anonymousaccess', 'cisauses'].any? {|k| search_params.key?(k)}
        
      query_obj = query_obj.joins("JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("JOIN isa_privs ON isa_assertion_structures.guid = isa_privs.isa_assertion_structure_guid")
        
      query_obj = query_obj.where('isa_privs.action' => 'DSPLY').where('isa_privs.effect' => search_params['dsply'].downcase) if search_params['dsply'].present?
      query_obj = query_obj.where('isa_privs.action' => 'IDSRC').where('isa_privs.effect' => search_params['idsrc'].downcase) if search_params['idsrc'].present?
      query_obj = query_obj.where('isa_privs.action' => 'TENOT').where('isa_privs.effect' => search_params['tenot'].downcase) if search_params['tenot'].present?
      query_obj = query_obj.where('isa_privs.action' => 'NETDEF').where('isa_privs.effect' => search_params['netdef'].downcase) if search_params['netdef'].present?
      query_obj = query_obj.where('isa_privs.action' => 'LEGAL').where('isa_privs.effect' => search_params['legal'].downcase) if search_params['legal'].present?
      query_obj = query_obj.where('isa_privs.action' => 'INTEL').where('isa_privs.effect' => search_params['intel'].downcase) if search_params['intel'].present?
      query_obj = query_obj.where('isa_privs.action' => 'TEARLINE').where('isa_privs.effect' => search_params['tearline'].downcase) if search_params['tearline'].present?
      query_obj = query_obj.where('isa_privs.action' => 'OPACTION').where('isa_privs.effect' => search_params['opaction'].downcase) if search_params['opaction'].present?
      query_obj = query_obj.where('isa_privs.action' => 'REQUEST').where('isa_privs.effect' => search_params['request'].downcase) if search_params['request'].present?
      query_obj = query_obj.where('isa_privs.action' => 'ANONYMOUSACCESS').where('isa_privs.effect' => search_params['anonymousaccess'].downcase) if search_params['anonymousaccess'].present?
      query_obj = query_obj.where('isa_privs.action' => 'CISAUSES').where('isa_privs.effect' => search_params['cisauses'].downcase) if search_params['cisauses'].present?
    end

    # Further Sharing Search
    if ['scope', 'effect'].any? {|k| search_params.key?(k)}
      query_obj = query_obj.joins("JOIN isa_assertion_structures ON stix_markings.stix_id = isa_assertion_structures.stix_marking_id")
        .joins("JOIN further_sharings ON isa_assertion_structures.guid = further_sharings.isa_assertion_structure_guid")
        
      query_obj = query_obj.where("lower(further_sharings.scope) like (?)", search_params['scope'].downcase) if search_params['scope'].present?
      query_obj = query_obj.where("lower(further_sharings.effect) like (?)", search_params['effect'].downcase) if search_params['effect'].present?
    end
    
    #ISA Marking Structure Search
    if ['re_custodian', 're_originator'].any? {|k| search_params.key?(k)}
      query_obj = query_obj.joins("JOIN isa_marking_structures ON stix_markings.stix_id = isa_marking_structures.stix_marking_id")
      
      query_obj = query_obj.where("lower(isa_marking_structures.re_custodian) like (?)", search_params['re_custodian'].downcase) if search_params['re_custodian'].present?
      if search_params['re_originator'].present?
        originator_term = search_params['re_originator'].downcase
        
        originator_term += '.%' if ['com', 'edu', 'int', 'npo'].any? {|abbr| abbr == originator_term}
        query_obj = query_obj.where("lower(isa_marking_structures.re_originator) like (?)", originator_term)
      end 
    end
              
    # AIS Consent Marking Structure Search
    if ['proprietary', 'ais_color'].any? {|k| search_params.key?(k)}
      if !isa_equiv_search
        query_obj = query_obj.joins("JOIN ais_consent_marking_structures ON stix_markings.stix_id = ais_consent_marking_structures.stix_marking_id")
      end
      
      query_obj = query_obj.where("lower(ais_consent_marking_structures.consent) like (?)", search_params['consent'].downcase) if search_params['consent'].present?
      if search_params['proprietary'].present?
        if ['t', 'true'].include?(search_params['proprietary'].downcase)
          query_obj = query_obj.where('ais_consent_marking_structures.proprietary' => true)
        elsif ['f', 'false'].include?(search_params['proprietary'].downcase)
          query_obj = query_obj.where('ais_consent_marking_structures.proprietary' => false)
        end
      end
      if search_params['ais_color'].present? and search_params['ais_color'].downcase != 'white'
        query_obj = query_obj.where("lower(ais_consent_marking_structures.color) like (?)", search_params['ais_color'].downcase)
      end 
    end
        
    # TLP Structure Search
    if search_params['tlp_color'].present? and search_params['tlp_color'].downcase != 'white'
      if !isa_equiv_search
        query_obj = query_obj.joins("JOIN tlp_structures ON stix_markings.stix_id = tlp_structures.stix_marking_id")
      end
      
      query_obj = query_obj.where("lower(tlp_structures.color) like (?)", search_params['tlp_color'].downcase)
    end 
      
    # Contributing Sources Search
    if ['organization_names', 'countries', 'administrative_areas', 'organization_info',
        'is_federal'].any? {|k| search_params.key?(k)}
      query_obj = query_obj.joins("JOIN contributing_sources ON stix_packages.stix_id = contributing_sources.stix_package_stix_id")
      
      query_obj = query_obj.where("stix_markings.remote_object_type = 'StixPackage'")
        .where("lower(contributing_sources.organization_names) like (?)", search_params['organization_names'].downcase) if search_params['organization_names'].present?
      query_obj = query_obj.where("stix_markings.remote_object_type = 'StixPackage'")
        .where("instr('|'||lower(contributing_sources.countries)||'|', '|'||?||'|')>0", search_params['countries'].downcase) if search_params['countries'].present?
      
      if search_params['administrative_areas'].present?
        if (search_params['administrative_areas'].match(/[?_]/))
          query_obj = query_obj.where("stix_markings.remote_object_type = 'StixPackage'")
            .where("lower(contributing_sources.administrative_areas) like (?)", search_params['administrative_areas'].downcase)
        else
          query_obj = query_obj.where("stix_markings.remote_object_type = 'StixPackage'")
            .where("instr('|'||lower(contributing_sources.administrative_areas)||'|', '|'||?||'|')>0", search_params['administrative_areas'].downcase)
        end
      end
         
      query_obj = query_obj.where("stix_markings.remote_object_type = 'StixPackage'")
        .where("lower(contributing_sources.organization_info) like (?)", search_params['organization_info'].downcase) if search_params['organization_info'].present?
      if search_params['is_federal'].present?
        if ['t', 'true'].include?(search_params['is_federal'].downcase)
          query_obj = query_obj.where("stix_markings.remote_object_type = 'StixPackage'")
            .where('contributing_sources.is_federal' => true)
        elsif ['f', 'false'].include?(search_params['is_federal'].downcase)
          query_obj = query_obj.where("stix_markings.remote_object_type = 'StixPackage'")
            .where('contributing_sources.is_federal' => false)
        end        
      end
    end
    
    return query_obj
  end
end