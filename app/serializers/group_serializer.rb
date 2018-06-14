class GroupSerializer < Serializer
  attributes :id,
             :name,
             :description,
             :created_at,
             :updated_at,
             :guid

  associate :permissions, {
    only: [
      :description, 
      :display_name, 
      :guid, 
      :id, 
      :name
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
end