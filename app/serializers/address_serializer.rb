class AddressSerializer < Serializer
  attributes :address,
             :address_input,
             :address_condition,
             :category,
             :cybox_object_id,
             :combined_score,
             :category_list,
             :created_at,
             :updated_at,
             :iso_country_code,
             :first_date_seen,
             :last_date_seen,
             :ip_value_calculated_start,
             :ip_value_calculated_end,
             :guid,
             :portion_marking,
             :read_only,
             :is_ciscp,
             :is_mifr,
             :feeds,
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

  associate :course_of_actions do single? end
  associate :ind_course_of_actions do single? end
  associate :dns_records do single? end
  associate :socket_addresses do single? end
  associate :stix_markings, include: [:isa_marking_structure,isa_assertion_structure: {include: {isa_privs: {except: [:scope_countries]}}}] do single? end
  associate :audits do single? end
  associate :badge_statuses do single? end

  node :indicators, ->{single?} do |address|
    array = []
    address.indicators.each do |i|
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

  associate :socket_addresses do single? end
  
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

  node :email_messages do |address|
    email_messages = []
    email_messages.push(address.email_senders) if address.email_senders.present?
    email_messages.push(address.email_reply_tos) if address.email_reply_tos.present?
    email_messages.push(address.email_froms) if address.email_froms.present?
    email_messages.push(address.email_x_ips) if address.email_x_ips.present?

    email_messages = email_messages.flatten.uniq

    e = email_messages.collect do |em|
      {
        cybox_object_id: em.cybox_object_id,
        x_originating_ip: em.x_originating_ip,
        from_normalized: em.from_normalized,
        reply_to_normalized: em.reply_to_normalized,
        sender_normalized: em.sender_normalized,
        subject: em.subject,
        subject_condition: em.subject_condition,
        created_at: em.created_at,
        updated_at: em.updated_at,
        portion_marking: em.portion_marking,
        from_normalized_c: em.from_normalized_c,
        sender_normalized_c: em.sender_normalized_c,
        reply_to_normalized_c: em.reply_to_normalized_c,
        x_originating_ip_c: em.x_originating_ip_c,
        subject_c: em.subject_c
      }
    end
    e
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