object @port

attributes :cybox_object_id,
           :port,
           :port_c,
           :layer4_protocol,
           :layer4_protocol_c,
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
end if (locals['port'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['port'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['port'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

child :socket_addresses => 'socket_addresses' do
  extends "socket_addresses/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['port'] || locals[:associations][:socket_addresses]) && locals[:associations][:socket_addresses] != 'none'

node :stix_markings do |port|
  stix_markings = port.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['port'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['port'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'