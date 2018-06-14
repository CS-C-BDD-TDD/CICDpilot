object @email

attributes :cybox_object_id,
           :email_date,
           :message_id,
           :subject,
           :subject_condition,
           :x_originating_ip,
           :created_at,
           :updated_at,
           :guid,
           :portion_marking,
           :read_only,
           :email_date_c,
           :subject_c,
           :x_originating_ip_c,
           :is_ciscp,
           :is_mifr,
		   :feeds           

if User.has_permission(current_user,'view_pii_fields')
  attributes :from_is_spoofed,
             :from_normalized,
             :from_input,
             :from_cybox_object_id,
             :raw_body,
             :raw_header,
             :reply_to_normalized,
             :reply_to_input,
             :reply_to_cybox_object_id,
             :sender_is_spoofed,
             :sender_normalized,
             :sender_input,
             :sender_cybox_object_id,
             :x_mailer,
             :from_normalized_c,
             :sender_normalized_c,
             :reply_to_normalized_c,
             :raw_body_c,
             :raw_header_c,
             :message_id_c,
             :x_mailer_c
end

child :links => 'links' do
  extends "links/email_show", locals: {associations: locals[:associations]}
end

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations].merge({confidences: 'embedded',observable: 'embedded'})}
end if (locals['email'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['email'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['email'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

node :stix_markings do |email|
  stix_markings = email.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['email'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :gfi => 'gfi' do
  extends "gfis/show", locals: {associations: locals[:associations]}
end if Setting.CLASSIFICATION && (locals['email'] || locals[:associations][:gfi]) && locals[:associations][:gfi] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['email'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
