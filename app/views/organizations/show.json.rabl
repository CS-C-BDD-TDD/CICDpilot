object @organization

attributes :id,
           :guid,
           :short_name,
           :long_name,
           :contact_info,
           :created_at,
           :updated_at,
           :organization_token

child :users do
  extends "users/index", locals: {associations: locals[:associations]}
end if (locals['organization'] || locals[:associations][:users]) && locals[:associations][:users] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['organization'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
