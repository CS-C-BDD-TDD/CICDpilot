class AcsSetSerializer < Serializer
  attributes :name,
             :id,
             :guid,
             :created_at,
             :updated_at,
             :color,
             :locked,
             :portion_marking

  associate :audits, {
    except: [
      :id, 
      :old_justification, 
      :audit_subtype, 
      :item_type_audited, 
      :item_guid_audited, 
      :guid
    ],
    include: [
      user: {
        only: [:guid, :username, :id]
      }
    ]
  } do single? end

  associate :stix_markings, {
    include: [
      isa_marking_structure: {except: :stix_marking_id},
      isa_assertion_structure: {
        except: [:stix_marking_id, :sharing_default],
        include: [
          isa_privs: {only: [:action, :effect, :id]}, 
          further_sharings: {}
        ]
      },
      tlp_marking_structure: {only: [:id, :stix_id, :color, :guid]},
      simple_marking_structure: {only: [:id, :consent, :guid, :color, :proprietary]},
      ais_consent_marking_structure: {except: [:stix_id, :stix_marking_id]}
    ]
  } do single? end

  associate :organizations do single? end

  node :indicators, ->{single?} do |acs_set|
    array = []
    acs_set.indicators.each do |i|
      hsh = i.as_json(single: false)
  
      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end

  associate :threat_actors, include: [:created_by_user] do single? end

  associate :course_of_actions do single? end

  associate :ttps do single? end

  associate :exploit_targets do single? end
  
  associate :stix_packages, include: [:created_by_user] do single? end

end