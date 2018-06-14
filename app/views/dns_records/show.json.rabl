object @dns_record

attributes :cybox_object_id,
           :address,
           :address_input,
           :domain,
           :domain_input,
           :entry_type,
           :address_class,
           :queried_date,
           :created_at,
           :updated_at,
           :guid,
           :portion_marking,
           :read_only,
           :address_c,
           :address_class_c,
           :domain_c,
           :entry_type_c,
           :queried_date_c,
           :is_ciscp,
           :is_mifr,
		   :feeds

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['dns_record'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['dns_record'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['dns_record'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

node :stix_markings do |dns_record|
  stix_markings = dns_record.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['dns_record'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :gfi => 'gfi' do
  extends "gfis/show", locals: {associations: locals[:associations]}
end if Setting.CLASSIFICATION && (locals['dns_record'] || locals[:associations][:gfi]) && locals[:associations][:gfi] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['dns_record'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
