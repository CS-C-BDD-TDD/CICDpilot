object false

child @metadata do
  attributes :total_count
end

child @uploaded_files, :root => "uploads" do
  if @uploaded_file.respond_to? "stix_packages"
    extends "uploads/show", locals: {associations: {stix_packages: @uploaded_file.stix_packages}}
  else
    extends "uploads/show"
  end
end
