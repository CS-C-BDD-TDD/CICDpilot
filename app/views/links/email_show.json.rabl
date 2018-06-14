object @link

attributes :cybox_object_id,
           :label,
           :label_condition,
           :updated_at,
           :created_at,
           :guid

if @link || (root_object && root_object != :link)
  link_to_use = @link
  if root_object
    link_to_use = root_object
  end

  child :uri => 'uri_attributes' do
    extends "uris/show.json.rabl", locals: {associations: locals[:associations]}
  end
end

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations].merge({confidences: 'embedded',observable: 'embedded'})}
end if (locals['link'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['link'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
