class SystemTagSerializer < Serializer
  attributes :name,
             :guid,
             :is_permanent,
             :id

  node :type do
    'system-tag'
  end

  node :indicators, ->{single?} do |system_tag|
    array = []
    system_tag.indicators.each do |i|
      hsh = i.as_json(single: false)

      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end 

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
    
end