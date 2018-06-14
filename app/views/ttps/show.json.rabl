object @ttp

attributes :stix_id,
           :created_at,
           :updated_at,
           :guid,
           :acs_set_id,
           :portion_marking,
           :read_only,
           :is_ciscp,
           :is_mifr,
		   :feeds

child :stix_packages => 'stix_packages' do
  extends "stix_packages/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['ttp'] || locals[:associations][:stix_packages]) && locals[:associations][:stix_packages] != 'none'

child :attack_patterns => 'attack_patterns' do
  extends "attack_patterns/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['ttp'] || locals[:associations][:attack_patterns]) && locals[:associations][:attack_patterns] != 'none'

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['ttp'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :exploit_targets => 'exploit_targets' do
  extends "exploit_targets/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['ttp'] || locals[:associations][:exploit_targets]) && locals[:associations][:exploit_targets] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['ttp'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'

child created_by_user: 'created_by_user' do |user|
  # need organization association on show
  extends "users/show", locals: {object: user, associations: locals[:associations]}
end if (locals['ttp'] || locals[:associations][:created_by_user]) && locals[:associations][:created_by_user] != 'none'

node :stix_markings do |ttp|
  stix_markings = ttp.stix_markings.to_a
  stix_markings += ttp.acs_set.stix_markings if ttp.acs_set.present?
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['ttp'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

node :acs_set do |ttp|
  acs_set = ttp.acs_set
  {name: acs_set.name,id: acs_set.id, portion_marking: acs_set.portion_marking} if acs_set.present?
end if (locals['ttp'] || locals[:associations][:acs_set]) && locals[:associations][:acs_set] != 'none'
