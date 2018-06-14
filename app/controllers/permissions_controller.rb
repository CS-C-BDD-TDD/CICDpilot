class PermissionsController < ApplicationController
  skip_before_filter :check_stix_permission
  
  def index
    @permissions = Permission.includes(:groups)
    @permissions = @permissions.find(params[:ids]) if params[:ids]
    @permissions = @permissions.where(groups: {id: params[:group_id]}) if params[:group_id]
    render json: @permissions
  end
  def show
    @permission = Permission.find(params[:id])
    render json: @permission
  end
  def create
    @permission = Permission.create(permission_params)
    validate(@permission)
  end
  def update
    @permission = Permission.find(params[:id]).tap{|s| s.update_attributes(permission_params)}
    validate(@permission)
  end
  def destroy
    Permission.find(params[:id]).destroy
    head 204
  end

private

  def permission_params
    params[:permission].permit(:name, :display_name, :description)
  end

  def validate(permission)
    if permission.valid?
      render(json: permission) && return
    else
      render json: {errors: permission.errors}, status: :unprocessable_entity
    end
  end

end
