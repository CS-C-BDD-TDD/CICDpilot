class DnsQuerySerializer < Serializer
  attributes :cybox_object_id,
             :question_normalized_cache,
             :answer_normalized_cache,
             :authority_normalized_cache,
             :additional_normalized_cache,
             :created_at,
             :updated_at,
             :guid,
             :portion_marking,
             :read_only,
             :is_ciscp,
             :is_mifr,
             :feeds,
             :total_sightings

  associate :indicators do single? end
  associate :course_of_actions do single? end
  associate :ind_course_of_actions do single? end

  associate :questions do single? end
  associate :resource_records do single? end

  associate :uris do single? end
  associate :dns_records do single? end
  
  associate :layer_seven_connections, {except: :guid, include: [:network_connections]} do single? end

  associate :audits, {include: [user: {only: [:username,:guid,:id]}]} do single? end
  associate :badge_statuses do single? end

  node :stix_markings, ->{single?} do |dns_query|
    if dns_query.class == DnsQuery
      stix_markings = dns_query.stix_markings
      stix_markings
    end
  end

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