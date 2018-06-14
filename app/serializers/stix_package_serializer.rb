class StixPackageSerializer < Serializer
  attributes :info_src_produced_time,
             :is_reference,
             :package_intent,
             :stix_id,
             :stix_timestamp,
             :title,
             :username,
             :color,
             :created_at,
             :updated_at,
             :guid,
             :acs_set_id,
             :uploaded_file_id,
             :submission_mechanism,
             :portion_marking,
             :read_only,
             :title_c,
             :package_intent_c,
             :is_ciscp,
             :is_mifr,
             :src_feed,
             :feeds,
             :short_description,
             :short_description_normalized,
             :description,
             :short_description_c,
             :description_c do
              if !User.has_permission(User.current_user,'view_pii_fields')
                pii_fields = [
                 :short_description,
                 :short_description_normalized,
                 :description,
                 :short_description_c,
                 :description_c
                ]
                return false if pii_fields.include?(@attr)
              end

              if @attr == :color && !single?
                return false
              end

              true
             end

  associate :badge_statuses do single? end
  node :indicators, ->{single?} do |package|
    array = []
    package.indicators.includes(:confidences, :official_confidence).each do |i|
      hsh = i.as_json(single: false)

      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end

  associate :acs_set, {only: [:guid,:name,:portion_marking]} do single? end

  associate :course_of_actions, {
  include: [
    observables: {
      include: [
        :address,:domain,:dns_record,:email_message,:uri,:http_session,:hostname, :network_connection, :port, :socket_address, :dns_query,
        mutex: {class_name: CyboxMutex, except: [:id, :cybox_hash]},
        registry: {include: :registry_values}, 
        file: {class_name: CyboxFile}, 
        link: {include: :uri}
      ],
      except: [:user_guid, :composite_operator, :id, :is_composite, :is_imported, :is_negated, :parent_id, :read_only]
    }
  ]
  } do single? end

  associate :exploit_targets do single? end

  associate :ttps do single? end

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

  node :stix_markings, ->{single?} do |stix_package|
    if stix_package.class == StixPackage
      stix_markings = stix_package.stix_markings
      stix_markings += stix_package.acs_set.stix_markings if stix_package.acs_set.present?
      stix_markings
    end
  end

  associate :contributing_sources do single? end

end