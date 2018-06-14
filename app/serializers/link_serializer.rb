class LinkSerializer < Serializer
  attributes :cybox_hash,
             :cybox_object_id,
             :label,
             :label_condition,
             :guid,
             :created_at,
             :updated_at,
             :portion_marking,
             :read_only,
             :label_c,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :total_sightings

  associate :badge_statuses do single? end
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

  associate :course_of_actions do single? end

  associate :ind_course_of_actions, {
    except: [
      :id, 
      :stix_timestamp, 
      :created_by_user_guid, 
      :updated_by_user_guid, 
      :created_by_organization_guid, 
      :updated_by_organization_guid
    ]
  } do single? end

  associate :email_messages, {
    include: [
      links: {
        include: [uri: {as: "uri_attributes"}],
        only: [
          :cybox_object_id, 
          :label,
          :label_condition,
          :updated_at,
          :created_at,
          :guid
        ]
      }
    ]  
  } do single? end

  node :indicators, ->{single?} do |link|
    array = []
    link.indicators.each do |i|
      hsh = i.as_json(single: false)
      
      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end

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

  #the difference between the two :uri's is that this one has no stix markings.
  #you cannot conditionally include (i.e only include the stix_markings if single?)
  #so this 2nd :uri is necessary.
  node :uri, ->{!single?} do |link|
    link.uri if link.uri.present?
  end

  associate :uri, {
    include: [stix_markings: {
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
    }]
  } do single? end

  associate :stix_packages, {
    except: :id, 
    include: [badge_statuses: {
      except: [
        :guid,
        :remote_object_id,
        :remote_object_type,
        :system,
        :created_at,
        :updated_at
      ]
    }]
  } do single? end
    
end
