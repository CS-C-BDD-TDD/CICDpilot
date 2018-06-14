object @uploaded_file

if User.has_permission(User.current_user, 'upload_for_transfer')
  attributes :id,
             :file_name,
             :file_size,
             :status,
             :validate_only,
             :overwrite,
             :read_only,
             :created_at,
             :updated_at,
             :portion_marking,
             :human_review_needed,
             :zip_status
else
  attributes :id,
             :file_name,
             :file_size,
             :status,
             :validate_only,
             :overwrite,
             :read_only,
             :created_at,
             :updated_at,
             :portion_marking,
             :human_review_needed
end

if @uploaded_file || (root_object && root_object != :uploads)
  file_to_use = @uploaded_file
  if root_object
    file_to_use = root_object
  end

  node :errors do |error|
    file_to_use.error_messages.collect(&:description)
  end

  node :warnings do |error|
    file_to_use.warnings.collect(&:description)
  end
end

child :stix_packages => 'stix_packages' do
  extends "stix_packages/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['uploaded_file'] || locals[:associations][:stix_packages]) && locals[:associations][:stix_packages] != 'none'

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations]}
end
