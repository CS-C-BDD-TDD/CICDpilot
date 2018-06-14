class ContributingSourceSerializer < Serializer
  	attributes :id,
  			:organization_names,
           	:countries,
           	:administrative_areas,
           	:organization_info,
           	:is_federal,
	   		:guid
	associate :stix_package, {except: :acs_set_id} do single? end
end
