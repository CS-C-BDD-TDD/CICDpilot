object @socket_address

attributes :cybox_object_id,
           :addresses_normalized_cache,
           :ports_normalized_cache,
           :hostnames_normalized_cache,
           :created_at,
           :updated_at,
           :guid,
           :portion_marking,
           :read_only,
           :is_ciscp,
           :is_mifr,
		   :feeds

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['socket_address'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['socket_address'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['socket_address'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

child :addresses => 'addresses' do
  extends "addresses/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['socket_address'] || locals[:associations][:addresses]) && locals[:associations][:addresses] != 'none'

child :hostnames => 'hostnames' do
  extends "hostnames/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['socket_address'] || locals[:associations][:hostnames]) && locals[:associations][:hostnames] != 'none'

child :ports => 'ports' do
  extends "ports/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['socket_address'] || locals[:associations][:ports]) && locals[:associations][:ports] != 'none'

node :stix_markings do |socket_address|
  stix_markings = socket_address.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['socket_address'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['socket_address'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'