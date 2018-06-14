class EmailMessagesController < ApplicationController
  include StixMarkingHelper
  
  def index
    @emails = EmailMessage.where(:cybox_object_id => params[:ids]) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0
    marking_search_params = nil
    if params[:marking_search_params].present?
      marking_search_params = JSON.parse params[:marking_search_params]
    end

    if params[:q].present?
      solr_offset = offset
      solr_limit = limit
      
      # If performing a SOLR based search AND a Stix Marking search we need to do a two-step query
      # First, we perform the SOLR based query and grab the ids of the first 1000 results.
      # We use those IDs to limit the SQL query that will feed the Stix Marking search
      if marking_search_params.present?
        solr_offset = 0
        solr_limit = 1000
      end
      search = Search.email_message_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        classification_limit: params[:classification_limit],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset
      })

      if marking_search_params.present?
        @emails ||= EmailMessage.all.reorder(created_at: :desc)
        @emails = @emails.where(id: search.results.collect {|eml| eml.id})
      else
        total_count = search.total
        @emails = search.results
      end

      @emails ||= []
    else
      @emails ||= EmailMessage.all.reorder(created_at: :desc)

      @emails = @emails.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @emails = @emails.where(from_normalized: params[:from]) if params[:from].present?
      @emails = @emails.where(reply_to_normalized: params[:reply_to]) if params[:reply_to].present?
      @emails = @emails.where(sender_normalized: params[:sender]) if params[:sender].present?
      @emails = @emails.where(subject: params[:subject]) if params[:subject].present?
      @emails = @emails.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
      @emails = apply_sort(@emails, params)
    end

    if marking_search_params.present?
      @emails = @emails.joins(:stix_markings)
      @emails = add_stix_markings_constraints(@emails, marking_search_params)
    end

    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @emails.count
      @emails = @emails.limit(limit).offset(offset)
    end
    
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, email_messages: @emails}}
      format.csv {render "email_messages/index.csv.erb"}
    end
  end

  def show
    @email = EmailMessage.includes(
        audits: :user,
        indicators: :confidences
    ).find_by_cybox_object_id(params[:id])
    if @email
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      EmailMessage.apply_default_policy_if_needed(@email)
      @email.reload

      render json: @email
    else
      render json: {errors: "Invalid email record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create email message observables"]}, status: 403
      return
    end
    
    #@email = EmailMessage.create(email_params)
    @email = EmailMessage.custom_save_or_update(nil, email_params)
    validate(@email)
  end

  def update
    @email = EmailMessage.find_by_cybox_object_id(params[:id])

    if !Permissions.can_be_modified_by(current_user,@email)
      render json: {errors: ["You do not have the ability to modify this email message observable"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    #@email.update(email_params)
    @email = EmailMessage.custom_save_or_update(@email, email_params)
    validate(@email)
  end

private

  def validate(object)
    if object.errors.blank? && object.valid?
      render(json: object) && return
    else
      render json: {errors: object.errors}, status: :unprocessable_entity
    end
  end

  def email_params
    if User.has_permission(current_user,'view_pii_fields')
      if gfi_permitted?
        params.permit(:cybox_object_id,
                      :email_date,
                      :from_input,
                      :from_is_spoofed,
                      :message_id,
                      :raw_body,
                      :raw_header,
                      :reply_to_input,
                      :sender_input,
                      :sender_is_spoofed,
                      :subject,
                      :subject_condition,
                      :x_mailer,
                      STIX_MARKING_PERMITTED_PARAMS,
                      :x_originating_ip,
                      :gfi_attributes=>GFI_ATTRIBUTES
                      )
      else
        params.permit(:cybox_object_id,
                      :email_date,
                      :from_input,
                      :from_is_spoofed,
                      :message_id,
                      :raw_body,
                      :raw_header,
                      :reply_to_input,
                      :sender_input,
                      :sender_is_spoofed,
                      :subject,
                      :subject_condition,
                      :x_mailer,
                      :x_originating_ip,
                      STIX_MARKING_PERMITTED_PARAMS
                      )
      end
    else
      if gfi_permitted?
        params.permit(:cybox_object_id,
                      :email_date,
                      :message_id,
                      :subject,
                      :subject_condition,
                      :x_originating_ip,
                      :guid,
                      STIX_MARKING_PERMITTED_PARAMS,
                      :cybox_object_id,
                      :gfi_attributes=>GFI_ATTRIBUTES
                      )
      else
        params.permit(:cybox_object_id,
                      :email_date,
                      :message_id,
                      :subject,
                      :subject_condition,
                      :x_originating_ip,
                      :guid,
                      STIX_MARKING_PERMITTED_PARAMS,
                      :cybox_object_id
                      )
      end
    end
  end

end
