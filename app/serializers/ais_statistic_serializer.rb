class AisStatisticSerializer < Serializer
  attributes :guid,
             :stix_package_stix_id,
             :stix_package_original_id,
             :dissemination_time,
             :dissemination_time_hr,
             :received_time,
             :feeds,
             :ais_uid,
             :indicator_amount,
             :flare_in_status,
             :ciap_status,
             :ecis_status,
             :flare_out_status,
             :ecis_status_hr,
             :flare_out_status_hr

  associate :system_logs do single? end
  
  node :human_review_count do |data|
    if data.human_review.present?
      data.human_review.comp_human_review_fields_count.to_s + "/" + data.human_review.human_review_fields_count.to_s
    else
      nil
    end
  end

end