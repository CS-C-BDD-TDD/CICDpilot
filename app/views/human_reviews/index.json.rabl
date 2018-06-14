object false

child @metadata do
  attributes :total_count
end
child @human_reviews, :root => 'human_reviews' do
  attributes :id,
             :decided_at,
             :status,
             :uploaded_file_id,
             :created_at,
             :updated_at

  node :fields_count do |human_review|
    human_review.comp_human_review_fields_count.to_s + ' / ' + human_review.human_review_fields_count.to_s
  end

  child :uploaded_file => 'uploaded_file' do
    attributes :file_name
  end if @human_reviews
  child :decided_by => 'decided_by' do
    attributes :username
  end if @human_reviews
end
