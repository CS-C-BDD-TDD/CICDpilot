class EmailMessageSerializer < Serializer
  attributes :cybox_object_id,
             :email_date,
             :message_id,
             :subject,
             :subject_condition,
             :x_originating_ip,
             :created_at,
             :updated_at,
             :guid,
             :from_is_spoofed,
             :from_normalized,
             :from_input,
             :from_cybox_object_id,
             :raw_body,
             :raw_header,
             :reply_to_normalized,
             :reply_to_input,
             :reply_to_cybox_object_id,
             :sender_is_spoofed,
             :sender_normalized,
             :sender_input,
             :sender_cybox_object_id,
             :x_mailer,
             :portion_marking,
             :read_only,
             :from_normalized_c,
             :sender_normalized_c,
             :reply_to_normalized_c,
             :subject_c,
             :email_date_c,
             :raw_body_c,
             :raw_header_c,
             :message_id_c,
             :x_mailer_c,
             :x_originating_ip_c,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :total_sightings
             
  associate :badge_statuses do single? end

  node :links, ->{!single?} do |email|
    links = email.links.collect do |l|
      {
        cybox_object_id: l.cybox_object_id,
        label: l.label,
        label_condition: l.label_condition,
        updated_at: l.updated_at,
        created_at: l.created_at,
        guid: l.guid,
        portion_marking: l.portion_marking,
        label_c: l.label_c,
        uri_attributes: {
          cybox_object_id: l.uri.cybox_object_id,
          updated_at: l.uri.updated_at,
          uri: l.uri.uri,
          uri_condition: l.uri.uri_condition,
          uri_input: l.uri.uri_input,
          uri_type: l.uri.uri_type,
          created_at: l.uri.created_at,
          guid: l.uri.guid,
          portion_marking: l.uri.portion_marking,
          read_only: l.uri.read_only
        }
      }
    end
  end

  node :links, ->{single?} do |email|
    links = email.links.collect do |l|
      {
        cybox_object_id: l.cybox_object_id,
        label: l.label,
        label_condition: l.label_condition,
        updated_at: l.updated_at,
        created_at: l.created_at,
        guid: l.guid,
        portion_marking: l.portion_marking,
        label_c: l.label_c,
        stix_markings: l.stix_markings,
        uri_attributes: {
          cybox_object_id: l.uri.cybox_object_id,
          updated_at: l.uri.updated_at,
          uri: l.uri.uri,
          uri_condition: l.uri.uri_condition,
          uri_input: l.uri.uri_input,
          uri_type: l.uri.uri_type,
          created_at: l.uri.created_at,
          guid: l.uri.guid,
          portion_marking: l.uri.portion_marking,
          stix_markings: l.uri.stix_markings,
          read_only: l.uri.read_only
        }
      }
    end
  end

  node :cybox_files, ->{single?} do |email|
    cybox_files = email.cybox_files.collect do |f|
      {
        file_name: f.file_name,
        file_extension: f.file_extension,
        file_name_condition: f.file_name_condition,
        file_path: f.file_path,
        file_path_condition: f.file_path_condition,
        size_in_bytes: f.size_in_bytes,
        size_in_bytes_condition: f.size_in_bytes_condition,
        cybox_hash: f.cybox_hash,
        cybox_object_id: f.cybox_object_id,
        read_only: f.read_only,
        file_name_c: f.file_name_c,
        file_path_c: f.file_path_c,
        size_in_bytes_c: f.size_in_bytes_c,
        md5: f.file_hashes.find_by_hash_type('MD5')?(f.file_hashes.find_by_hash_type('MD5').simple_hash_value):"",
        md5_c: f.file_hashes.find_by_hash_type('MD5')?(f.file_hashes.find_by_hash_type('MD5').simple_hash_value_normalized_c):"",
        sha1: f.file_hashes.find_by_hash_type('SHA1')?(f.file_hashes.find_by_hash_type('SHA1').simple_hash_value):"",
        sha1_c: f.file_hashes.find_by_hash_type('SHA1')?(f.file_hashes.find_by_hash_type('SHA1').simple_hash_value_normalized_c):"",
        sha256: f.file_hashes.find_by_hash_type('SHA256')?(f.file_hashes.find_by_hash_type('SHA256').simple_hash_value):"",
        sha256_c: f.file_hashes.find_by_hash_type('SHA256')?(f.file_hashes.find_by_hash_type('SHA256').simple_hash_value_normalized_c):"",
        ssdeep: f.file_hashes.find_by_hash_type('SSDEEP')?(f.file_hashes.find_by_hash_type('SSDEEP').fuzzy_hash_value):"",
        ssdeep_c: f.file_hashes.find_by_hash_type('SSDEEP')?(f.file_hashes.find_by_hash_type('SSDEEP').fuzzy_hash_value_normalized_c):"",
        created_at: f.created_at,
        updated_at: f.updated_at,
        guid: f.guid,
        portion_marking: f.portion_marking,
        stix_markings: f.stix_markings
      }
    end
  end

  node :stix_markings, ->{single?} do |email|
    if email.class == EmailMessage
      stix_markings = email.stix_markings
      stix_markings
    end
  end

  node :addresses, -> {single?} do |email|
    addresses = []
    addresses.push(email.sender_address) if email.sender_address.present?
    addresses.push(email.reply_to_address) if email.reply_to_address.present?
    addresses.push(email.from_address) if email.from_address.present?
    addresses.push(email.x_ip_address) if email.x_ip_address.present?

    a = addresses.collect do |a|
      {
        address: a.address_value_normalized,
        address_condition: a.address_condition,
        cybox_object_id: a.cybox_object_id,
        created_at: a.created_at,
        portion_marking: a.portion_marking,
        stix_markings: a.stix_markings
      }
    end

    a
  end

  node :indicators, ->{single?} do |email|
    array = []
    email.indicators.each do |i|
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
