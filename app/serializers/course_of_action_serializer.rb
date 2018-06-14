class CourseOfActionSerializer < Serializer
  attributes :stix_id,
             :title,
             :created_at,
             :updated_at,
             :guid,
             :title_c,
             :description,
             :description_c,
             :acs_set_id,
             :portion_marking,
             :read_only,
             :created_at,
             :updated_at,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :description_normalized
             
  associate :badge_statuses do single? end

  node :indicators, ->{single?} do |coa|
    array = []
    coa.indicators.each do |i|
      hsh = i.as_json(single: false)

      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end

  associate :observables, {
    include: [
      :address,:domain,:dns_record,:email_message,:uri,:http_session,:hostname, :network_connection, :port, :socket_address, :dns_query,
      mutex: {class_name: CyboxMutex, except: [:id, :cybox_hash]},
      registry: {include: :registry_values}, 
      file: {class_name: CyboxFile}, 
      link: {include: :uri}
    ],
    except: [:user_guid, :composite_operator, :id, :is_composite, :is_imported, :is_negated, :parent_id, :read_only]
  } do single? end

  associate :parameter_observables, {except: :id, include: [
      :address,:domain,:dns_record,:email_message,:uri,:http_session,:hostname, :network_connection, :port, :socket_address,
      :dns_query,
      mutex: {class_name: CyboxMutex},
      registry: {include: :registry_values}, file: {class_name: CyboxFile,include: :file_hashes}, link: {include: :uri}
  ]} do single? end

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

  node :stix_markings, ->{single?} do |coa|
    if coa.class == CourseOfAction
      stix_markings = coa.stix_markings
      stix_markings += coa.acs_set.stix_markings if coa.acs_set.present?
      stix_markings
    end
  end

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

  associate :acs_set, {only: [:guid,:name,:portion_marking]} do single? end
end