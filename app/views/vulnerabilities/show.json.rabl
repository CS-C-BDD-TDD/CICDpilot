object @vulnerability

attributes :id,
           :title,
           :title_c,
           :description,
           :description_c,
           :description_normalized,
           :cve_id,
           :cve_id_c,
           :osvdb_id,
           :osvdb_id_c,
           :created_at,
           :updated_at,
           :guid,
           :portion_marking,
           :read_only

child :exploit_targets => 'exploit_targets' do
  extends "exploit_targets/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['vulnerability'] || locals[:associations][:exploit_targets]) && locals[:associations][:exploit_targets] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['vulnerability'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'

child created_by_user: 'created_by_user' do |user|
  # need organization association on show
  extends "users/show", locals: {object: user, associations: locals[:associations]}
end if (locals['vulnerability'] || locals[:associations][:created_by_user]) && locals[:associations][:created_by_user] != 'none'

node :stix_markings do |vulnerability|
  stix_markings = vulnerability.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['vulnerability'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'
