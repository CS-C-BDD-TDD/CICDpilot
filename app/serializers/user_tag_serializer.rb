class UserTagSerializer < Serializer
  attributes :name,
             :guid,
             :user_guid,
             :id

  node :type do
    'user-tag'
  end

  node :indicators, ->{single?} do |user_tag|
    array = []
    user_tag.indicators.each do |i|
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