class UserSerializer < Serializer
  attributes :guid,
             :id,
             :api_key, #TODO restrict this based on permissions
             :email,
             :first_name,
             :last_name,
             :phone,
             :username,
             :machine,
             :created_at,
             :updated_at,
             :disabled_at,
             :expired_at,
             :remote_guid,
             :terms_accepted_at

  associate :organization

  associate :groups, {
    except: [
      :created_by_id,
      :updated_by_id
    ]  
  }

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

  node :isa_entity_cache, ->{single?} do |user|
    if user.class == User
      isa_entity_cache = user.isa_entity_cache
      isa_entity_cache
    end
  end 
end