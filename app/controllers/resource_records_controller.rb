class ResourceRecordsController < ApplicationController
  
  def index
    @resource_records = ResourceRecord.where(:guid => params[:ids]) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    if params[:q].present?
      search = Search.resource_record_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (limit || Sunspot.config.pagination.default_per_page),
        offset: offset,
        classification_limit: params[:classification_limit]
      })
      total_count = search.total
      @resource_records = search.results

      @resource_records ||= []
    else
      @resource_records ||= ResourceRecord.all.reorder(created_at: :desc)

      @resource_records = @resource_records.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @resource_records = apply_sort(@resource_records, params)
      @resource_records = @resource_records.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])

      total_count = @resource_records.count
      @resource_records = @resource_records.limit(limit).offset(offset)
    end
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, resource_records: @resource_records} }
      format.csv {render "dns_queries/resource_records/index.csv.erb"}
    end

  end

  def show
    @resource_record = 
    ResourceRecord.includes(
      :dns_records,
      audits: :user
    ).find_by_guid(params[:id])

    if @resource_record
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      ResourceRecord.apply_default_policy_if_needed(@resource_record)
      @resource_record.reload

      render json: @resource_record
    else
      render json: {errors: "Could not find Resource Record Object"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create Resource Record Object"]}, status: 403
      return
    end
    
    @resource_record = ResourceRecord.new(resource_record_params)

    validation_errors = {:base => []}

    begin
      @resource_record.save!
    rescue Exception => e
      validation_errors[:base] << e.to_s
    end

    if @resource_record.errors.present?
      validation_errors[:base] << @resource_record.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @resource_record
    else
      render json: {errors: @resource_record.errors}, status: :unprocessable_entity
    end
  end

  def update
    @resource_record = ResourceRecord.find_by_guid(params[:id])

    unless Permissions.can_be_modified_by(current_user,@resource_record)
      render json: {errors: ["You do not have the ability to modify this Resource Record Object"]}, status: 403
      return
    end

    Audit.justification = params[:justification] if params[:justification]
    @resource_record.update(resource_record_params)

    validation_errors = {:base => []}
    
    if @resource_record.errors.present?
      validation_errors[:base] << @resource_record.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @resource_record
    else
      render json: {errors: @resource_record.errors}, status: :unprocessable_entity
    end
  end

private

  def resource_record_params
    params.permit(
      :guid,
      :record_type,
      STIX_MARKING_PERMITTED_PARAMS,
      :dns_record_cybox_object_ids => []
    )
  end

end
