class QuestionsController < ApplicationController
  
  def index
    @questions = Question.where(:guid => params[:ids]) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    if params[:q].present?
      search = Search.question_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (limit || Sunspot.config.pagination.default_per_page),
        offset: offset,
        classification_limit: params[:classification_limit]
      })
      total_count = search.total
      @questions = search.results

      @questions ||= []
    else
      @questions ||= Question.all.reorder(created_at: :desc)

      @questions = @questions.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @questions = apply_sort(@questions, params)
      @questions = @questions.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])

      total_count = @questions.count
      @questions = @questions.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, questions: @questions} }
      format.csv {render "dns_queries/questions/index.csv.erb"}
    end

  end

  def show
    @question = 
    Question.includes(
      :uris,
      audits: :user
    ).find_by_guid(params[:id])

    if @question
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      Question.apply_default_policy_if_needed(@question)
      @question.reload

      render json: @question
    else
      render json: {errors: "Could not find Question Object"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create Question Object"]}, status: 403
      return
    end
    
    @question = Question.new(question_params)

    validation_errors = {:base => []}

    begin
      @question.save!
    rescue Exception => e
      validation_errors[:base] << e.to_s
    end

    if @question.errors.present?
      validation_errors[:base] << @question.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @question
    else
      render json: {errors: @question.errors}, status: :unprocessable_entity
    end
  end

  def update
    @question = Question.find_by_guid(params[:id])

    unless Permissions.can_be_modified_by(current_user,@question)
      render json: {errors: ["You do not have the ability to modify this Question Object"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @question.update(question_params)

    validation_errors = {:base => []}
    
    if @question.errors.present?
      validation_errors[:base] << @question.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @question
    else
      render json: {errors: @question.errors}, status: :unprocessable_entity
    end
  end

private

  def question_params
    params.permit(
      :guid,
      :qclass,
      :qtype,
      STIX_MARKING_PERMITTED_PARAMS,
      :uri_cybox_object_ids => []
    )
  end

end
