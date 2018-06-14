class GroupsController < ApplicationController
  skip_before_filter :check_stix_permission

  def index
    @groups = Group.includes(:permissions)
    @groups = @groups.find(params[:ids]) if params[:ids]
    @groups ||= Group.all
    render json: @groups
  end
  def show
    @group = Group.find(params[:id])
    render json: @group
  end
  def create
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage groups"]}, status: 403
      return
    end

    @group = Group.create(group_params)
    validate(@group)
  end
  def update
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage groups"]}, status: 403
      return
    end

    @group = Group.find(params[:id])
    @group.update(group_params)
    validate(@group)
  end
  def destroy
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to delete groups"]}, status: 403
      return
    end

    Group.find(params[:id]).destroy
    head 204
  end

private

  def group_params
    params[:permission_ids] ||= []
    params.permit(:name, :description, :permission_ids => [])
  end

  def validate(group)
    if group.valid?
      render(json: group) && return
    else
      render json: {errors: group.errors}, status: :unprocessable_entity
    end
  end

end
