class HumanReviewSerializer < Serializer
  attributes :id,
             :decided_at,
             :status,
             :uploaded_file_id,
             :created_at,
             :updated_at

  node :fields_count, ->{!single?} do |human_review|
    if human_review.comp_human_review_fields_count.present? && human_review.human_review_fields_count.present?
      human_review.comp_human_review_fields_count.to_s + ' / ' + human_review.human_review_fields_count.to_s
    end
  end

  node :uploaded_file, ->{single?} do |human_review|
    human_review.uploaded_file
  end

  associate :uploaded_file, only: :file_name do !single? end

  node :human_review_fields_count, ->{single?} do |human_review|
    human_review.human_review_fields_count
  end

  node :comp_human_review_fields_count, ->{single?} do |human_review|
    human_review.comp_human_review_fields_count
  end

  associate :human_review_fields do single? end

  associate :decided_by, {
    except: [
      :api_key_secret_encrypted,
      :failed_login_attempts,
      :hidden_at,
      :locked_at,
      :logged_in_at,
      :notes,
      :organization_guid,
      :password_change_required,
      :password_changed_at,
      :password_hash,
      :password_salt,
      :r5_id,
      :throttle
    ]
  }

end