object @threat_actor

attributes :stix_id,
           :title,
           :created_at,
           :updated_at,
           :guid,
           :identity_name,
           :title_c,
           :identity_name_c,
           :acs_set_id,
           :portion_marking,
           :read_only


if User.has_permission(current_user,'view_pii_fields')
  attributes :short_description,
             :description,
             :short_description_c,
             :description_c
end

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['threat_actor'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['threat_actor'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'

child created_by_user: 'created_by_user' do |user|
  # need organization association on show
  extends "users/show", locals: {object: user, associations: locals[:associations]}
end

node :stix_markings do |threat_actor|
  stix_markings = threat_actor.stix_markings.to_a
  stix_markings += threat_actor.acs_set.stix_markings if threat_actor.acs_set.present?
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['threat_actor'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

node :acs_set do |threat_actor|
  acs_set = threat_actor.acs_set
  {name: acs_set.name,id: acs_set.id, portion_marking: acs_set.portion_marking} if acs_set.present?
end
