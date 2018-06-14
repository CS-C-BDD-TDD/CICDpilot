if @stix_packages
  object false

  child @metadata do
    attributes :total_count
  end

  child @stix_packages, :root => "stix_packages" do
  	extends "stix_packages/show", locals: {associations: locals[:associations]}
  end

else
  collection @stix_packages

  extends("stix_packages/show", locals: {associations: locals[:associations]})
end
