object @stix_package

attributes :info_src_produced_time,
           :is_reference,
           :package_intent,
           :stix_id,
           :stix_timestamp,
           :title,
           :username,
           :color,
           :created_at,
           :updated_at,
           :guid,
           :acs_set_id,
           :uploaded_file_id,
           :submission_mechanism,
           :portion_marking,
           :read_only,
           :title_c,
           :package_intent_c,
           :is_ciscp,
           :is_mifr,
		   :feeds

if User.has_permission(current_user,'view_pii_fields')
  attributes :short_description,
             :short_description_normalized,
             :description,
             :short_description_c,
             :description_c
end

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['stix_package'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :acs_set => 'acs_set' do
  attributes :id, :name, :portion_marking
end

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['stix_package'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :exploit_targets => 'exploit_targets' do
  extends "exploit_targets/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['stix_package'] || locals[:associations][:exploit_targets]) && locals[:associations][:exploit_targets] != 'none'

child :ttps => 'ttps' do
  extends "ttps/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['stix_package'] || locals[:associations][:ttps]) && locals[:associations][:ttps] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['stix_package'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'

child created_by_user: 'created_by_user' do |user|
  # need organization association on show
  extends "users/show", locals: {object: user, associations: locals[:associations]}
end

node :stix_markings do |package|
  stix_markings = package.stix_markings.to_a
  stix_markings += package.acs_set.stix_markings if package.acs_set.present?
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['stix_package'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :contributing_sources => 'contributing_sources' do
  extends "sources/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['stix_package'] || locals[:associations][:contributing_sources]) && locals[:associations][:contributing_sources] != 'none'