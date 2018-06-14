class ExportedIndicatorSerializer < Serializer
  attributes :id,
             :system,
             :color,
             :guid,
             :exported_at,
             :description,
             :indicator_id,
             :user_id,
             :detasked_at,
             :updated_at,
             :status,
             :sid2,
             :comments_normalized,
             :date_added,
             :event,
             :event_classification,
             :nai,
             :nai_classification,
             :special_instructions,
             :sid,
             :reference,
             :cs_regex,
             :clear_text,
             :signature_location,
             :ps_regex,
             :observable_value,
             :indicator_title,
             :indicator_stix_id,
             :indicator_type,
             :indicator_classification,
             :indicator_type_classification,
             :username,
             :comments

  node :indicator do |exp_ind|
    hsh = exp_ind.indicator.as_json(single: false)
    if hsh.present?
        hsh[:acs_set] = (exp_ind.indicator.present? && exp_ind.indicator.acs_set.present?) ? {id: exp_ind.indicator.acs_set.guid, name: exp_ind.indicator.acs_set.name, portion_marking: exp_ind.indicator.acs_set.portion_marking} : nil
    end
    
    hsh
  end

  node :user do |exp_ind|
    {
      id: exp_ind.user.id, 
      guid: exp_ind.user.guid, 
      username: exp_ind.user.username
    } if exp_ind.user.present?
  end
end