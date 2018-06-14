class IndicatorSerializer < Serializer
  attributes :composite_operator,
             :description,
             :indicator_type,
             :reference,
             :indicator_type_vocab_name,
             :indicator_type_vocab_ref,
             :is_composite,
             :is_negated,
             :is_reference,
             :parent_id,
             :resp_entity_stix_ident_id,
             :stix_id,
             :dms_label,
             :stix_timestamp,
             :title,
             :created_at,
             :updated_at,
             :guid,
             :downgrade_request_id,
             :color,
             :alternative_id,
             :acs_set_id,
             :from_weather_map,
             :portion_marking,
             :read_only,
             :title_c,
             :description_c,
             :indicator_type_c,
             :dms_label_c,
             :downgrade_request_id_c,
             :reference_c,
             :alternative_id_c,
             :timelines,
             :source_of_report,
             :target_of_attack,
             :target_scope,
             :actor_attribution,
             :actor_type,
             :modus_operandi,
             :observable_type,
             :observable_value,
             :threat_actor_id,
             :threat_actor_title,
             :is_ais,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :start_time,
             :end_time,
             :id

  associate :badge_statuses do single? end
  associate :observables, {except: :id, include: [
      :address,:domain,:dns_record,:email_message,:uri,:http_session,:hostname, :network_connection, :port, :socket_address,
      :dns_query,
      mutex: {class_name: CyboxMutex},
      registry: {include: :registry_values}, file: {class_name: CyboxFile,include: :file_hashes}, link: {include: :uri}
  ]} do single? end

  associate :official_confidence do single? end

  associate :confidences, {include: [user: {only: [:username,:guid,:id]}]} do single? end

  node :confidences, ->{!single?} do |i|
    [{value: i.official_confidence.value}] if i.official_confidence.present?
  end

  associate :acs_set, {only: [:guid,:name,:portion_marking]} do single? end

  associate :sightings, {include: [user: {only: [:username,:guid,:id]}]} do single? end

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

  node :exported_indicators, ->{ single? } do |indicator|
	  indicator.exported_indicators.with_deleted
  end

  associate :notes, {include: :user} do single? && User.has_permission(User.current_user,'view_analyst_notes') end

  associate :audits, {
    except: [
      :id, 
      :old_justification, 
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

  associate :threat_actors, {include: :created_by_user} do single? end
    
  associate :course_of_actions do single? end

  associate :ttps do single? end

  associate :system_tags do single? end

  associate :kill_chains, {except: [:created_at,:updated_at]} do single? end

  associate :kill_chain_phases, {except: [:created_at,:updated_at]} do single? end

  associate :weather_map_addresses do single? end

  associate :weather_map_domains do single? end

  node :user_tags, ->{single? && User.has_permission(User.current_user,'tag_item_with_user_tag')} do |indicator|
    indicator.user_tags.where(user_guid: User.current_user.guid)
  end

  node :stix_markings, ->{single?} do |indicator|
    if indicator.class == Indicator
      stix_markings = indicator.stix_markings
      stix_markings += indicator.acs_set.stix_markings if indicator.acs_set.present?
      stix_markings
    end
  end

  node :related_indicators, ->{single?} do |indicator|
    if indicator.class == Indicator
      related_indicators = indicator.related_to_objects.collect do |r|
        {
            guid: r.guid,
            confidences: r.confidences.as_json,
            relationship_type: r.relationship_type,
            stix_information_source_id: r.stix_information_source_id,
            created_at: r.created_at,
            updated_at: r.updated_at,
            indicator: r.remote_dest_object.as_json(single: false)
        }
      end

      related_indicators += indicator.related_by_objects.collect do |r|
        {
            guid: r.guid,
            confidences: r.confidences.as_json,
            relationship_type: r.relationship_type,
            stix_information_source_id: r.stix_information_source_id,
            created_at: r.created_at,
            updated_at: r.updated_at,
            indicator: r.remote_src_object.as_json(single: false)
        }
      end
      related_indicators
    end
  end

  node :attachments, ->{single?} do |indicator|
    attachments = indicator.attachments.collect do |a|
      {
        id: a.uploaded_file.id,
        file_name: a.uploaded_file.file_name,
        username: User.find_by_guid(a.uploaded_file.user_guid).username,
        created_at: a.created_at,
        ref_title: a.uploaded_file.reference_title,
        ref_num: a.uploaded_file.reference_number,
        ref_link: a.uploaded_file.reference_link
      }
    end
    attachments
  end
end
