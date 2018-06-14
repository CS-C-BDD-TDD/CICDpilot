class BadgeStatusesController < ApplicationController
  
  def index
    @badge_statuses = BadgeStatus.where(:guid => params[:ids]) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    @badge_statuses ||= BadgeStatus.all.reorder(created_at: :desc)

    @badge_statuses = @badge_statuses.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
    @badge_statuses = apply_sort(@badge_statuses, params)

    total_count = @badge_statuses.count
    @badge_statuses = @badge_statuses.limit(limit).offset(offset)
    
    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, badge_statuses: @badge_statuses} }
    end

  end

  def show
    if !User.has_permission(current_user, 'view_badge_status')
      render json: {errors: ["You do not have the ability to view badge statuses"]}, status: 403
      return
    end

    @badge_status = BadgeStatus.find_by_guid(params[:id]) || BadgeStatus.find_by_remote_object_id(params[:id])
    if @badge_status
      render json: @badge_status
    else
      render json: {errors: "Invalid badge status record number"}, status: 400
    end
  end

  def create
    if !User.has_permission(current_user, 'modify_all_items') or !User.has_permission(current_user, 'create_remove_badge_status')
      render json: {errors: ["You do not have the ability to create badge statuses"]}, status: 403
      return
    end
    
    @badge_status = BadgeStatus.new(badge_status_params)

    validation_errors = {:base => []}

    begin
      @badge_status.save!
    rescue Exception => e
      validation_errors[:base] << e.to_s
    end

    if @badge_status.errors.present?
      validation_errors[:base] << @badge_status.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @badge_status
    else
      render json: {errors: @badge_status.errors}, status: :unprocessable_entity
    end
  end

  def update
    @badge_status = BadgeStatus.find_by_guid(params[:id])

    unless Permissions.can_be_modified_by(current_user,@badge_status) and User.has_permission(current_user, 'create_remove_badge_status')
      render json: {errors: ["You do not have the ability to modify this badge status"]}, status: 403
      return
    end

    @badge_status.update(badge_status_params)

    validation_errors = {:base => []}
    
    if @badge_status.errors.present?
      validation_errors[:base] << @badge_status.errors.messages
    end

    # if validate comes back with errors, we probably have a error
    if validation_errors[:base].blank?
      render json: @badge_status
    else
      render json: {errors: @badge_status.errors}, status: :unprocessable_entity
    end
  end

  def destroy
    @badge_status = BadgeStatus.find_by_guid(params[:id])
    if !Permissions.can_be_deleted_by(current_user, @badge_status) and User.has_permission(current_user, 'create_remove_badge_status')
      render json: {errors: ["You do not have the ability to delete badges"]}, status: 403
      return
    end
    if @badge_status.system
      render json: {errors: ["You cannot delete a system badge"]}, status: 403
      return
    elsif @badge_status.destroy
      render json: @badge_status
    else
      render json: {errors:["Badge could not be deleted"] },status: :unprocessable_entity
    end
  end

private

  def badge_status_params
    params.permit(
      :guid,
      :badge_name,
      :badge_status,
      :remote_object_id,
      :remote_object_type
    )
  end

end
