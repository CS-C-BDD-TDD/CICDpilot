object @link

attributes :cybox_object_id,
           :label,
           :label_condition,
           :updated_at,
           :created_at,
           :guid,
           :portion_marking,
           :read_only,
           :label_c,
           :is_ciscp,
           :is_mifr,
		   :feeds

if @link || (root_object && root_object != :link)
  link_to_use = @link
  if root_object
    link_to_use = root_object
  end

  child :uri => 'uri' do
    extends "uris/show.json.rabl", locals: {associations: locals[:associations]}
    
    child :stix_markings do
      extends 'stix_markings/index.json.rabl'
    end if (locals['link'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'
  end
end

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations].merge({confidences: 'embedded',observable: 'embedded'})}
end if (locals['link'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['link'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['link'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

child :email_messages => 'email_messages' do
  extends "email_messages/show.json.rabl", locals: {associations: locals[:associations]}
end if (locals['link'] || locals[:associations][:email_messages]) && locals[:associations][:stix_markings] != 'none'

node :stix_markings do |link|
  stix_markings = link.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['link'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['link'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
