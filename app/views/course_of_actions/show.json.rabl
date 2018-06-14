object @course_of_action

attributes :stix_id,
           :title,
           :created_at,
           :updated_at,
           :guid,
           :title_c,
           :acs_set_id,
           :portion_marking,
           :read_only,
           :created_at,
           :updated_at,
           :is_ciscp,
           :is_mifr,
		   :feeds


if User.has_permission(current_user,'view_pii_fields')
  attributes :description,
             :description_c,
             :description_normalized
end

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['course_of_action'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :observables => 'observables' do
  extends "observables/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['course_of_action'] || locals[:associations][:observables]) && locals[:associations][:observables] != 'none'

child :parameter_observables => 'parameter_observables' do
  extends "parameter_observables/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['course_of_action'] || locals[:associations][:parameter_observables]) && locals[:associations][:parameter_observables] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['course_of_action'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'

child created_by_user: 'created_by_user' do |user|
  # need organization association on show
  extends "users/show", locals: {object: user, associations: locals[:associations]}
end if (locals['course_of_action'] || locals[:associations][:created_by_user]) && locals[:associations][:created_by_user] != 'none'

node :stix_markings do |course_of_action|
  stix_markings = course_of_action.stix_markings.to_a
  stix_markings += course_of_action.acs_set.stix_markings if course_of_action.acs_set.present?
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['course_of_action'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :stix_packages => 'stix_packages' do
  extends "stix_packages/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['course_of_action'] || locals[:associations][:stix_packages]) && locals[:associations][:stix_packages] != 'none'

node :acs_set do |course_of_action|
  acs_set = course_of_action.acs_set
  {name: acs_set.name,id: acs_set.id, portion_marking: acs_set.portion_marking} if acs_set.present?
end if (locals['course_of_action'] || locals[:associations][:acs_set]) && locals[:associations][:acs_set] != 'none'
