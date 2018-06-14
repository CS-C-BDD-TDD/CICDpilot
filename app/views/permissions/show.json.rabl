object @permission

attributes :id,
           :display_name,
           :description,
           :name,
           :guid

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['permissions'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
