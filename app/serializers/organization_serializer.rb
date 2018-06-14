class OrganizationSerializer < Serializer
  attributes :id,
             :guid,
             :short_name,
             :long_name,
             :contact_info,
             :created_at,
             :updated_at,
             :organization_token

  associate :users, {
    except: [
      :api_key_secret_encrypted, 
      :failed_login_attempts,
      :hidden_at,
      :locked_at,
      :logged_in_at,
      :notes,
      :organization_guid,
      :password_change_required,
      :password_changed_at,
      :password_hash,
      :password_salt,
      :r5_id,
      :throttle
    ],
    include: [
      groups: {except: [:created_by_id, :updated_by_id]},
      organization: {except: [:acs_sets_org_id, :category, :r5_id, :releasability_mask]}
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