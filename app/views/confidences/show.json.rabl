object @confidence

attributes :value,
           :is_official,
           :description,
           :source,
           :stix_timestamp

node :set_at do |confidence|
  confidence.created_at
end

child :user do
  attributes :guid,:username,:id
end