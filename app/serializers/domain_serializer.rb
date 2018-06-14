class DomainSerializer < Serializer
  attributes :name,
             :name_condition,
             :cybox_hash,
             :cybox_object_id,
             :name_type,
             :created_at,
             :updated_at,
             :combined_score,
             :category_list,
             :iso_country_code,
             :first_date_seen,
             :last_date_seen,
             :guid,
             :portion_marking,
             :read_only,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :root_domain,
             :name_input,
             :com_threat_score,
             :gov_threat_score,
             :total_sightings,
             :agencies_sensors_seen_on do
              if Setting.MODE != "CIAP"
                exclude_fields = [
                 :com_threat_score,
                 :gov_threat_score,
                 :agencies_sensors_seen_on
                ]
                return false if exclude_fields.include?(@attr)
              end

              true
             end

  if Setting.CLASSIFICATION == true
    associate :gfi do single? end
  end
  
  associate :badge_statuses do single? end

  node :indicators, ->{single?} do |domain|
    array = []
    domain.indicators.each do |i|
      hsh = i.as_json(single: false)
      
      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end 

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