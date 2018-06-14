class BadgeStatusSerializer < Serializer
  attributes :guid,
             :badge_name,
             :badge_status,
             :remote_object_id,
             :remote_object_type,
             :system,
             :created_at,
             :updated_at

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

  node :remote_audits, ->{single?} do |badge|
    array = []
    badge.remote_object.audits.each do |i|
      hsh = i.as_json(single: false)

      array << hsh
    end
    array
  end
end
