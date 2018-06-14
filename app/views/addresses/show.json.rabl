object @address

attributes :address,
           :address_input,
           :address_condition,
           :category,
           :cybox_object_id,
           :created_at,
           :updated_at,
           :iso_country_code,
           :combined_score,
           :first_date_seen,
           :last_date_seen,
           :ip_value_calculated_start,
           :ip_value_calculated_end,
           :category_list,
           :guid,
           :portion_marking,
           :read_only,
           :is_ciscp,
		   :is_mifr,
		   :feeds

if Setting.MODE == "CIAP"
  attributes :com_threat_score,
             :gov_threat_score,
             :agencies_sensors_seen_on
end

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['address'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['address'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['address'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

child :socket_addresses => 'socket_addresses' do
  extends "socket_addresses/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['address'] || locals[:associations][:socket_addresses]) && locals[:associations][:socket_addresses] != 'none'

node :stix_markings do |address|
  stix_markings = address.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['address'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :gfi => 'gfi' do
  extends "gfis/show", locals: {associations: locals[:associations]}
end if Setting.CLASSIFICATION && (locals['address'] || locals[:associations][:gfi]) && locals[:associations][:gfi] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['address'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'

node :email_messages do |address|
  email_messages = []
  email_messages.push(address.email_senders) if address.email_senders.present?
  email_messages.push(address.email_reply_tos) if address.email_reply_tos.present?
  email_messages.push(address.email_froms) if address.email_froms.present?
  email_messages.push(address.email_x_ips) if address.email_x_ips.present?

  email_messages = email_messages.flatten.uniq

  e = email_messages.collect do |em|
    {
      cybox_object_id: em.cybox_object_id,
      x_originating_ip: em.x_originating_ip,
      from_normalized: em.from_normalized,
      reply_to_normalized: em.reply_to_normalized,
      sender_normalized: em.sender_normalized,
      subject: em.subject,
      subject_condition: em.subject_condition,
      created_at: em.created_at,
      updated_at: em.updated_at,
      portion_marking: em.portion_marking,
      from_normalized_c: em.from_normalized_c,
      sender_normalized_c: em.sender_normalized_c,
      reply_to_normalized_c: em.reply_to_normalized_c,
      x_originating_ip_c: em.x_originating_ip_c,
      subject_c: em.subject_c
    }
  end

  e
end if (locals['address'] || locals[:associations][:email_messages]) && locals[:associations][:email_messages] != 'none'

node :dns_records do |address|
  dns_records = address.dns_records

  e = dns_records.collect do |dr|
    {
      cybox_object_id: dr.cybox_object_id,
      address_value_normalized: dr.address_value_normalized,
      address_class: dr.address_class,
      description: dr.description,
      domain_normalized: dr.domain_normalized,
      entry_type: dr.entry_type,
      queried_date: dr.queried_date,
      created_at: dr.created_at,
      updated_at: dr.updated_at,
      portion_marking: dr.portion_marking,
      address_value_normalized_c: dr.address_value_normalized_c,
      address_class_c: dr.address_class_c,
      domain_normalized_c: dr.domain_normalized_c,
      entry_type_c: dr.entry_type_c,
      queried_date_c: dr.queried_date_c
    }
  end

  e
end if (locals['address'] || locals[:associations][:dns_records]) && locals[:associations][:dns_records] != 'none'

