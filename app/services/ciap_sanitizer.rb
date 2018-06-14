class CiapSanitizer < Stix::Stix111::StixSanitizer
  # Find persisted mappings
  def find_existing_mapping(uid)
    map_row = nil
    map_row = CiapIdMapping.where(before_id: uid).first

    if map_row.nil? && uid.start_with?('NCCIC')
      # If the uid is prefixed with "NCCIC," check to see if a mapping
      # already exists with this uid as the after_id and return the
      # after_id if it does to help prevent double sanitization when it
      # comes from AIS.
      map_row = CiapIdMapping.where(after_id: uid).first
    end

    map_obj = nil
    map_obj = {before_id: uid, after_id: map_row.after_id, persisted_id: map_row.id} if map_row.present?

    return map_obj
  end
  
  # Persistence
  def persist_mapping(before_id, after_id)
    map_row = CiapIdMapping.new(before_id: before_id, after_id: after_id)
    map_row.save
    Audit.where(item_type_audited: 'CiapIdMapping').all.each {|x| x.delete}
    
    return map_row
  end

end