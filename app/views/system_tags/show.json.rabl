object @system_tag

attributes :name,
           :guid,
           :is_permanent,
           :id

node :type do
  'system-tag'
end

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['system_tag'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'