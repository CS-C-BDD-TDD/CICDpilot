object false

child @metadata do
	attributes :total_count
end

child @exported_indicators do
	attributes :guid,
	           :color,
	           :system,
	           :exported_at,
	           :description,
	           :status,
	           :detasked_at

	child :indicator => 'indicator' do
		extends "indicators/show.json.rabl", locals: {associations: locals[:associations]}
	end if @exported_indicators

	child :user do
		attributes :guid,:username,:id
	end if @exported_indicators
end