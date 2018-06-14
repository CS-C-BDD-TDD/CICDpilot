class UriSerializer < Serializer
  attributes :cybox_object_id,
             :updated_at,
             :uri,
             :uri_short,
             :uri_input,
             :uri_type,
             :uri_condition,
             :guid,
             :created_at,
             :updated_at,
             :guid,
             :portion_marking,
             :read_only,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :total_sightings

  associate :badge_statuses do single? end
  node :indicators, ->{single?} do |address|
    array = []
    address.indicators.each do |i|
      hsh = i.as_json(single: false)

      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end 

  associate :course_of_actions do single? end

  associate :ind_course_of_actions, {
    except: [
      :id, 
      :stix_timestamp, 
      :created_by_user_guid, 
      :updated_by_user_guid, 
      :created_by_organization_guid, 
      :updated_by_organization_guid
    ]
  } do single? end

  associate :email_messages do single? end

  associate :links, {
    include: :uri
  } do single? end

  associate :questions do single? end

  node :stix_markings, ->{single?} do |uri|
    if uri.class == Uri
      stix_markings = uri.stix_markings
      stix_markings
    end
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

  associate :stix_packages, {
    except: :id, 
    include: [badge_statuses: {
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

end