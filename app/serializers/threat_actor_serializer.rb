class ThreatActorSerializer < Serializer
  attributes :stix_id,
             :title,
             :created_at,
             :updated_at,
             :guid,
             :identity_name,
             :title_c,
             :identity_name_c,
             :acs_set_id,
             :portion_marking,
             :read_only,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :short_description,
             :description,
             :short_description_c,
             :description_c do
              if !User.has_permission(User.current_user,'view_pii_fields')
                pii_fields = [
                 :short_description,
                 :description,
                 :short_description_c,
                 :description_c
                ]
                return false if pii_fields.include?(@attr)
              end

              true
             end

  associate :badge_statuses do single? end
  node :indicators, ->{single?} do |threat_actor|
    array = []
    threat_actor.indicators.each do |i|
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
  }

  node :stix_markings, ->{single?} do |threat_actor|
    if threat_actor.class == ThreatActor
      stix_markings = threat_actor.stix_markings.to_a
      stix_markings += threat_actor.acs_set.stix_markings if threat_actor.acs_set.present?
      stix_markings
    end
  end 

  associate :acs_set, {only: [:guid, :portion_marking, :name]}
end