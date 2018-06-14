object @sighting

attributes :id,
           :description,
           :sighted_at,
           :stix_indicator_id,
           :guid

child :user do
  attributes :guid,:username,:id
end

child :audits => 'audits' do
  extends "audits/index"
end if (locals['sighting'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
