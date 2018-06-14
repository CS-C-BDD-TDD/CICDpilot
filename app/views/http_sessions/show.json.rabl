object @http_session

attributes :cybox_object_id,
           :user_agent,
           :user_agent_condition,
           :domain_name,
           :port,
           :referer,
           :pragma,
           :created_at,
           :updated_at,
           :guid,
           :portion_marking,
           :read_only,
           :user_agent_c,
           :domain_name_c,
           :port_c,
           :referer_c,
           :pragma_c,
           :is_ciscp,
           :is_mifr,
		   :feeds,
           :display_name

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations].merge({confidences: 'embedded',observable: 'embedded'})}
end if (locals['http_session'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['http_session'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['http_session'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

node :stix_markings do |http_session|
  stix_markings = http_session.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['http_session'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['http_session'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
