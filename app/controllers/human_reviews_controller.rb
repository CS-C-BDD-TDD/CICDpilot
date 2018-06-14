class HumanReviewsController < ApplicationController
  before_filter :permission_check

  def index
    @human_reviews = HumanReview.all
    @human_reviews = @human_reviews.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
    @human_reviews = @human_reviews.where.not(status: 'R').where.not(status: 'A') if params[:in_progress].present? && params[:in_progress].to_bool
    total_count = @human_reviews.count

    if params[:column] == 'file_name' && (params[:direction].downcase == 'asc' || params[:direction].downcase == 'desc')
      # Modified code this way to avoid security finding
      if params[:direction].downcase == 'asc'
        @human_reviews = @human_reviews.joins(:uploaded_file).reorder("uploaded_files.file_name asc").preload(:uploaded_file)
      else
        @human_reviews = @human_reviews.joins(:uploaded_file).reorder("uploaded_files.file_name desc").preload(:uploaded_file)
      end
    else
      @human_reviews = apply_sort(@human_reviews, params).includes(:uploaded_file,:decided_by)
    end

    limit = record_limit(params[:amount].to_i || params[:limit].to_i)
    offset = params[:offset] || 0

    @human_reviews = @human_reviews.limit(limit).offset(offset)

    @metadata = Metadata.new
    @metadata.total_count = total_count

    if params[:count].present? && params[:count].to_bool
      render json: {count: total_count}
    else
      render json: {metadata: @metadata, human_reviews: @human_reviews}
    end
  end

  def show
    @human = HumanReview.find_by_id(params[:id])

    render json: @human
  end

  def update
    @human = HumanReview.find_by_id(params[:id])
    updates = human_review_params

    transaction_status=nil
    # Grab all human review fields attributes
    human_review_fields_attributes = updates[:human_review_fields_attributes]
    count=0
    # Start a transaction, because if ANY of this fails, we need to fail
    ActiveRecord::Base.transaction do
      # Process the attributes 1000 records at a time
      while (count*1000)<human_review_fields_attributes.count
        updates[:human_review_fields_attributes] = human_review_fields_attributes[(count*1000)..((count*1000)+999)]
        transaction_status=@human.update(updates)
        count+=1
      end
      raise ActiveRecord::Rollback unless transaction_status
    end

    if transaction_status==false
      render json: {errors: @human.errors.full_messages}, status: :unprocessible_entity
    elsif @human.valid?
      render json: @human
    else
      render json: {errors: @human.errors.full_messages}
    end

  end

  def disseminate
    @human = HumanReview.find_by_id(params[:id])
    @human.decided_at = Time.now
    @human.decided_by = User.current_user
    @human.status = 'A'
    @human.save!

    if @human.valid?
      render json: @human
    else
      render json: {errors: @human.errors.full_messages}
    end
  end

  def human_review_params
    params.permit(
        :id,
        :status,
        :human_review_fields_attributes => [:id,:object_field_revised, :has_pii]
    )
  end

  private

  def permission_check
    unless User.has_permission(current_user, 'human_review')
      render json: {errors: ["You do not have the ability to perform reviews"]}, status: 403
      return
    end
  end
end
