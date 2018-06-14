class TtpSerializer < Serializer
  attributes :stix_id,
             :created_at,
             :updated_at,
             :guid,
             :acs_set_id,
             :portion_marking,
             :read_only,
             :is_ciscp,
             :is_mifr,
             :feeds

  associate :badge_statuses do single? end
  associate :stix_packages, {
    except: :id, 
    include: [:acs_set, badge_statuses: {
      except: [
        :guid,
        :remote_object_id,
        :remote_object_type,
        :system,
        :created_at,
        :updated_at
      ]
    }]
  } do single? end

  associate :attack_patterns, {
    except: :id, 
    include: [created_by_user: {
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
    }]
  } do single? end

  node :indicators, ->{single?} do |address|
    array = []
    address.indicators.each do |i|
      hsh = i.as_json(single: false)
      
      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end 

  associate :exploit_targets, {
    except: :id, 
    include: [created_by_user: {
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
    }]
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

  associate :created_by_user, {
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

  node :stix_markings, ->{single?} do |ttp|
    if ttp.class == Ttp
      stix_markings = ttp.stix_markings
      stix_markings += ttp.acs_set.stix_markings if ttp.acs_set.present?
      stix_markings
    end
  end

  associate :acs_set, {only: [:guid,:name,:portion_marking]} do single? end
end
