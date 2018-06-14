object @hostname

attributes :cybox_object_id,
           :hostname,
           :hostname_c,
           :hostname_input,
           :hostname_condition,
           :naming_system,
           :naming_system_c,
           :is_domain_name,
           :created_at,
           :updated_at,
           :guid,
           :portion_marking,
           :read_only,
           :is_ciscp,
           :is_mifr,
		   :feeds

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations].merge({confidences: 'embedded',observable: 'embedded'})}
end if (locals['hostname'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['hostname'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['hostname'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

child :socket_addresses => 'socket_addresses' do
  extends "socket_addresses/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['hostname'] || locals[:associations][:socket_addresses]) && locals[:associations][:socket_addresses] != 'none'

node :stix_markings do |hostname|
  stix_markings = hostname.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['hostname'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['hostname'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'