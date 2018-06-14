object @human_review

attributes :id,
           :decided_at,
           :decided_by,
           :status,
           :uploaded_file_id,
           :created_at,
           :updated_at

node :fields_count do |human_review|
  human_review.comp_human_review_fields_count.to_s + ' / ' + human_review.human_review_fields_count.to_s
end

child :uploaded_file => 'uploaded_file' do
  extends "uploads/show", locals: {associations: locals[:associations]}
end if (locals['human_review'] || locals[:associations][:uploaded_file]) && locals[:associations][:uploaded_file] != 'none'
