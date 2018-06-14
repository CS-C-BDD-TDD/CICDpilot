class StixMarkingSerializer < Serializer
  attributes :controlled_structure,
             :guid,
             :remote_object_type,
             :remote_object_id,
             :remote_object_field,
             :stix_id,
             :id,
             :created_at,
             :updated_at

  associate :isa_marking_structure

  associate :isa_assertion_structure, {include: [:further_sharings,isa_privs: {only: [:action,:effect,:id,:guid]}]}

  associate :tlp_marking_structure, {only: [:id,:stix_id,:color,:guid]}

  associate :simple_marking_structure, {only: [:id,:stix_id,:guid,:statement]}

  associate :ais_consent_marking_structure
  
  node :remote_object, ->{remote_object.present?} do |marking|
    remote_object = {}
    remote_object['remote_object_type'] = marking.remote_object_type
    remote_object['guid'] = marking.remote_object.guid
     
    if marking.remote_object.respond_to?(:stix_id)
      remote_object['stix_id'] = marking.remote_object.stix_id
    end
    
    if marking.remote_object.respond_to?(:cybox_object_id)
      remote_object['cybox_object_id'] = marking.remote_object.cybox_object_id
    end

    if marking.remote_object.respond_to?(:contributing_sources)
      remote_object['contributing_sources'] = marking.remote_object.contributing_sources
    end
    
    remote_object
  end
end