object @attack_pattern

attributes :stix_id,
           :title,
           :title_c,
           :description,
           :description_c,
           :description_normalized,
           :capec_id,
           :capec_id_c,
           :created_at,
           :updated_at,
           :guid,
           :portion_marking,
           :read_only

child :ttps => 'ttps' do
  extends "ttps/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['attack_pattern'] || locals[:associations][:ttps]) && locals[:associations][:ttps] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['attack_pattern'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'

child created_by_user: 'created_by_user' do |user|
  # need organization association on show
  extends "users/show", locals: {object: user, associations: locals[:associations]}
end

node :stix_markings do |attack_pattern|
  stix_markings = attack_pattern.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['attack_pattern'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'
