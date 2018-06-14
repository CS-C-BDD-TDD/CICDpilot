class SightingSerializer < Serializer
  attributes :id,
             :description,
             :sighted_at,
             :stix_indicator_id,
             :guid

  associate :user, {only: [:username,:guid,:id]} do single? end

  associate :confidences, {include: [user: {only: [:username,:guid,:id]}]} do single? end

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