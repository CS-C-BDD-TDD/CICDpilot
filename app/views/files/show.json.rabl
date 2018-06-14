object @file

attributes :cybox_object_id,
           :file_extension,
           :file_name,
           :file_name_condition,
           :file_path,
           :file_path_condition,
           :size_in_bytes,
           :size_in_bytes_condition,
           :stix_indicator_id,
           :stix_observable_id,
           :created_at,
           :updated_at,
           :guid,
           :portion_marking,
           :read_only,
           :file_name_c,
           :file_path_c,
           :size_in_bytes_c,
           :is_ciscp,
           :is_mifr,
		   :feeds

if @file || (root_object && root_object != :file)
  file_to_use = @file
  if root_object
    file_to_use = root_object
  end

  file_to_use.file_hashes.collect do |hash|
    if (locals['file'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'
      node do |dummy|
        if hash.simple_hash_value.present?
          {
            hash.hash_type.downcase.to_sym => hash.simple_hash_value, 
            (hash.hash_type.downcase + "_c").to_sym => hash.simple_hash_value_normalized_c,
            (hash.hash_type.downcase + "_stix_markings").to_sym => (partial 'stix_markings/index.json.rabl', object: hash.stix_markings)
          }
        else
          {
            hash.hash_type.downcase.to_sym => hash.fuzzy_hash_value,
            (hash.hash_type.downcase + "_c").to_sym => hash.fuzzy_hash_value_normalized_c,
            (hash.hash_type.downcase + "_stix_markings").to_sym => (partial 'stix_markings/index.json.rabl', object: hash.stix_markings)
          }
        end
      end
    else
      node do |dummy|
        if hash.simple_hash_value.present?
          {
            hash.hash_type.downcase.to_sym => hash.simple_hash_value, 
            (hash.hash_type.downcase + "_c").to_sym => hash.simple_hash_value_normalized_c
          }
        else
          {
            hash.hash_type.downcase.to_sym => hash.fuzzy_hash_value,
            (hash.hash_type.downcase + "_c").to_sym => hash.fuzzy_hash_value_normalized_c
          }
        end
      end
    end
  end
end

child :file_hashes => 'file_hashes' do
  attributes :id,:hash_type, :simple_hash_value_normalized_c, :fuzzy_hash_value_normalized_c
  attributes simple_hash_value_normalized: :simple_hash_value,fuzzy_hash_value_normalized: :fuzzy_hash_value
end

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations].merge({confidences: 'embedded',observable: 'embedded'})}
end if (locals['file'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :email_messages => 'email_messages' do
  extends "email_messages/show.json.rabl", locals: {associations: locals[:associations]}
end if (locals['file'] || locals[:associations][:email_messages]) && locals[:associations][:stix_markings] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['file'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['file'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

node :stix_markings do |file|
  stix_markings = file.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['file'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :gfi => 'gfi' do
  extends "gfis/show", locals: {associations: locals[:associations]}
end if Setting.CLASSIFICATION && (locals['file'] || locals[:associations][:gfi]) && locals[:associations][:gfi] != 'none'

node :audits do |file|
  audits = file.audits.to_a
  file.file_hashes.each do |fh|
    audits += fh.audits.to_a if fh.audits.present?
  end
  partial 'audits/index', object: audits
end if (locals['file'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'