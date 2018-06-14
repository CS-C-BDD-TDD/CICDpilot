class CyboxFileSerializer < Serializer
  attributes :file_name,
             :file_extension,
             :file_name_condition,
             :file_path,
             :file_path_condition,
             :size_in_bytes,
             :size_in_bytes_condition,
             :cybox_hash,
             :cybox_object_id,
             :md5,
             :portion_marking,
             :read_only,
             :file_name_c,
             :file_path_c,
             :created_at,
             :updated_at,
             :size_in_bytes_c,
             :guid,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :total_sightings

  if Setting.CLASSIFICATION
    associate :gfi do single? end
  end
  
  associate :badge_statuses do single? end

  node :indicators, ->{single?} do |file|
    array = []
    file.indicators.each do |i|
      hsh = i.as_json(single: false)
  
      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end

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

  if Setting.CLASSIFICATION
    associate :gfi do single? end
  end

  node :audits, ->{single?} do |file|
    array = []
    file.audits.each do |a|
      hsh = a.as_json(single: false)
      hsh.delete("audit_subtype")
      hsh.delete("id")
      hsh.delete("item_guid_audited")
      hsh.delete("item_type_audited")
      hsh.delete("guid")
      hsh.delete("old_justification")
      hsh[:user] = {guid: a.user.guid, id: a.user.id, username: a.user.username} if a.user.present?
      array << hsh
    end

    file.file_hashes.each do |fh|
      fh.audits.each do |a|
        hsh = a.as_json(single: false)
        hsh.delete("audit_subtype")
        hsh.delete("id")
        hsh.delete("item_guid_audited")
        hsh.delete("item_type_audited")
        hsh.delete("guid")
        hsh.delete("old_justification")
        hsh[:user] = {guid: a.user.guid, id: a.user.id, username: a.user.username} if a.user.present?
        array << hsh
      end
    end

    array
  end

  #stores the data for the 3 nodes of each hash type (e.g. md5, md5_c, md5_stix_markings)
  hash_type_nodes = {}

  node :file_hashes do |file|
    array = []
    hash_type_nodes = {}
    file.file_hashes.each do |hash|

      #since we are already iterating through the file hashes for this node,
      #might as well gather all the data needed for the hash type nodes to avoid repeating
      #the same iterations.
      if hash.simple_hash_value.present?
        hash_type_nodes[hash.hash_type.downcase.to_sym] = hash.simple_hash_value
        hash_type_nodes[(hash.hash_type.downcase + "_c").to_sym] = hash.simple_hash_value_normalized_c
      elsif hash.fuzzy_hash_value.present?
        hash_type_nodes[hash.hash_type.downcase.to_sym] = hash.fuzzy_hash_value
        hash_type_nodes[(hash.hash_type.downcase + "_c").to_sym] = hash.fuzzy_hash_value_normalized_c
      end

      hash_type_nodes[(hash.hash_type.downcase + "_stix_markings").to_sym] = hash.stix_markings if hash.stix_markings.present?

      hsh = {
        id: hash.id,
        hash_type: hash.hash_type,
        simple_hash_value_normalized_c: hash.simple_hash_value_normalized_c,
        fuzzy_hash_value_normalized_c: hash.fuzzy_hash_value_normalized_c,
        simple_hash_value: hash.simple_hash_value_normalized,
        fuzzy_hash_value: hash.fuzzy_hash_value_normalized
      }
      array << hsh
    end
    array
  end

  #these hash type nodes must come after the file_hashes node because that is where
  #the values of hash_type_nodes are set. this is done so the file hashes don't have
  #to be iterated over more than once
  node :md5 do |file|
    hash_type_nodes[:md5] if hash_type_nodes[:md5].present?
  end

  node :md5_c do |file|
    hash_type_nodes[:md5_c] if hash_type_nodes[:md5_c].present?
  end

  node :md5_stix_markings, ->{single?} do |file|
    hash_type_nodes[:md5_stix_markings] if hash_type_nodes[:md5_stix_markings].present?
  end

  node :sha1 do |file|
    hash_type_nodes[:sha1] if hash_type_nodes[:sha1].present?
  end

  node :sha1_c do |file|
    hash_type_nodes[:sha1_c] if hash_type_nodes[:sha1_c].present?
  end

  node :sha1_stix_markings, ->{single?} do |file|
    hash_type_nodes[:sha1_stix_markings] if hash_type_nodes[:sha1_stix_markings].present?
  end

  node :sha256 do |file|
    hash_type_nodes[:sha256] if hash_type_nodes[:sha256].present?
  end

  node :sha256_c do |file|
    hash_type_nodes[:sha256_c] if hash_type_nodes[:sha256_c].present?
  end

  node :sha256_stix_markings, ->{single?} do |file|
    hash_type_nodes[:sha256_stix_markings] if hash_type_nodes[:sha256_stix_markings].present?
  end

  node :ssdeep do |file|
    hash_type_nodes[:ssdeep] if hash_type_nodes[:ssdeep].present?
  end

  node :ssdeep_c do |file|
    hash_type_nodes[:ssdeep_c] if hash_type_nodes[:ssdeep_c].present?
  end

  node :ssdeep_stix_markings, ->{single?} do |file|
    hash_type_nodes[:ssdeep_stix_markings] if hash_type_nodes[:ssdeep_stix_markings].present?
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