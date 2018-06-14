object @user

attributes :guid,
           :id,
           :api_key, #TODO restrict this based on permissions
           :email,
           :first_name,
           :last_name,
           :phone,
           :username,
           :machine,
           :created_at,
           :updated_at,
           :disabled_at,
           :expired_at,
           :remote_guid,
           :terms_accepted_at

child :organization do
  extends "organizations/show", locals: {associations: locals[:associations]}
end unless locals[:associations][:organization] == 'none'

child :groups do
  extends "groups/index", locals: {associations: locals[:associations]}
end if locals[:associations][:groups] != 'none'

child :permissions do
  extends "permissions/index", locals: {associations: locals[:associations]}
end if (locals['user'] || locals[:associations][:permissions]) && locals[:associations][:permissions] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['user'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'

child :isa_entity_cache => 'isa_entity_cache' do
  attributes :id,
             :admin_org,
             :ato_status,
             :clearance,
             :country,
             :access_groups,
             :distinguished_name,
             :duty_org,
             :entity_class,
             :entity_type,
             :created_at,
             :updated_at
end if (locals['user'] || locals[:associations][:isa_entity_cache]) && locals[:associations][:isa_entity_cache] != 'none'