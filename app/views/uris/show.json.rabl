object @uri

attributes :cybox_object_id,
           :updated_at,
           :uri,
           :uri_short,
           :uri_condition,
           :uri_input,
           :uri_type,
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
end if (locals['uri'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['uri'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['uri'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

child :email_messages => 'email_messages' do
  extends "email_messages/show.json.rabl", locals: {associations: locals[:associations]}
end if (locals['uri'] || locals[:associations][:email_messages]) && locals[:associations][:stix_markings] != 'none'

child :links => 'links' do
  extends "links/show.json.rabl", locals: {associations: locals[:associations]}
end if (locals['uri'] || locals[:associations][:links]) && locals[:associations][:stix_markings] != 'none'

node :stix_markings do |uri|
  stix_markings = uri.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['uri'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['uri'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
