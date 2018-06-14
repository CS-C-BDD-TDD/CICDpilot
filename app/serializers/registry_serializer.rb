class RegistrySerializer < Serializer
  attributes :cybox_object_id,
             :hive,
             :hive_condition,
             :key,
             :created_at,
             :updated_at,
             :guid,
             :portion_marking,
             :read_only,
             :hive_c,
             :key_c,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :total_sightings

  associate :badge_statuses do single? end
  node :reg_value_id do |registry|
    registry.registry_values[0].id if registry.registry_values[0].present?
  end

  node :reg_name do |registry|
    registry.registry_values[0].reg_name if registry.registry_values[0].present?
  end

  node :data_condition do |registry|
    registry.registry_values[0].data_condition if registry.registry_values[0].present?
  end

  node :reg_value do |registry|
    registry.registry_values[0].reg_value if registry.registry_values[0].present?
  end

  node :reg_name_c do |registry|
    registry.registry_values[0].reg_name_c if registry.registry_values[0].present?
  end

  node :reg_value_c do |registry|
    registry.registry_values[0].reg_value_c if registry.registry_values[0].present?
  end

  node :reg_stix_markings, ->{single?} do |registry|
    registry.registry_values[0].stix_markings if registry.registry_values[0].present?
  end

  node :indicators, ->{single?} do |address|
    array = []
    address.indicators.each do |i|
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