object @user_tag

attributes :name,
           :guid,
           :user_guid,
           :id

node :type do
  'user-tag'
end

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['user_tag'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['user_tag'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'