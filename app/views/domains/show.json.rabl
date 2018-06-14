object @domain

attributes :cybox_object_id,
           :name,
           :name_input,
           :name_condition,
           :root_domain,
           :created_at,
           :updated_at,
           :iso_country_code,
           :combined_score,
           :first_date_seen,
           :last_date_seen,
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
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations].merge({confidences: 'embedded',observable: 'embedded'})}
end if (locals['domain'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['domain'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['domain'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

node :stix_markings do |domain|
  stix_markings = domain.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['domain'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :gfi => 'gfi' do
  extends "gfis/show", locals: {associations: locals[:associations]}
end if Setting.CLASSIFICATION && (locals['domain'] || locals[:associations][:gfi]) && locals[:associations][:gfi] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['domain'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'