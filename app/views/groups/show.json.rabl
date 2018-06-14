object @group

attributes :id,
           :name,
           :description,
           :created_at,
           :updated_at,
           :guid

child :permissions do
  extends "permissions/index", locals: {associations: locals[:associations]}
end if (locals['group'] || locals[:associations][:permissions]) && locals[:associations][:permissions] != 'none'

child :audits => 'audits' do
  extends "audits/index"
end if (locals['group'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
