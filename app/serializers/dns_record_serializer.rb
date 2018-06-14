class DnsRecordSerializer < Serializer

  attributes :cybox_object_id,
             :address,
             :address_input,
             :domain,
             :domain_input,
             :entry_type,
             :address_class,
             :queried_date,
             :created_at,
             :updated_at,
             :guid,
             :portion_marking,
             :read_only,
             :address_c,
             :address_class_c,
             :domain_c,
             :entry_type_c,
             :queried_date_c,
             :record_name,
             :record_type,
             :ttl,
             :flags,
             :data_length,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :total_sightings

  associate :badge_statuses do single? end
  
  node :indicators, ->{single?} do |dns_record|
    array = []
    dns_record.indicators.each do |i|
      hsh = i.as_json(single: false)
      
      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end

  associate :course_of_actions, {except: :id} do single? end

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

  associate :resource_records, {except: :id} do single? end
    
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

  associate :dns_address, {class_name: Address, serializer: AddressSerializer, include: {stix_markings: {include: [:isa_marking_structure, isa_assertion_structure: {include: :isa_privs}]}}} do single? end
  associate :dns_domain, {class_name: Domain, serializer: DomainSerializer, include: {stix_markings: {include: [:isa_marking_structure, isa_assertion_structure: {include: :isa_privs}]}}} do single? end

  if Setting.CLASSIFICATION
    associate :gfi do single? end
  end

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