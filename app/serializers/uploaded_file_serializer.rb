class UploadedFileSerializer < Serializer
  attributes :id,
             :file_name,
             :file_size,
             :status,
             :validate_only,
             :overwrite,
             :read_only,
             :created_at,
             :updated_at,
             :portion_marking,
             :human_review_needed,
             :zip_status

  node :errors do |upload|
    upload.error_messages.collect(&:description)
  end

  node :warnings do |upload|
    upload.warnings.collect(&:description)
  end

  associate :stix_packages do single? end
  associate :avp_message do single? end
  associate :original_inputs, {include: [ciap_id_mappings: {only: [:original_id, :sanitized_id]}]} do single? end

  node :indicators, ->{single?} do |upload|
    array = []
    upload.indicators.each do |i|
      hsh = i.as_json(single: false)
  
      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end

end
