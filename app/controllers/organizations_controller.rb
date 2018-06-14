class OrganizationsController < ApplicationController
  skip_before_filter :check_stix_permission
  
  def index
    if !User.has_permission(current_user, 'view_user_organization')
      render json: {errors: ["You do not have the ability to view organizations"]}, status: 403
      return
    end
    @organizations = Organization.includes(:audits, :users) # eager loading goes here
    @organizations = @organizations.find(params[:ids]) if params[:ids]
    @organizations ||= Organization.all
    render json: @organizations
  end
  def show
    if !User.has_permission(current_user, 'view_user_organization')
      render json: {errors: ["You do not have the ability to view organizations"]}, status: 403
      return
    end
    @organization = Organization.includes(:users,audits: :user).find_by_guid(params[:id])
    render json: @organization
  end
  def create
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage organizations"]}, status: 403
      return
    end
    @organization = Organization.new(organization_params)
    if @organization.save
      render json: @organization
    else
      render json: {errors: @organization.errors}, status: :unprocessable_entity
    end
  end
  def update
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage organizations"]}, status: 403
      return
    end
    @organization = Organization.find_by_guid(params[:id])
    @organization.update_attributes(organization_params)
    if @organization.valid?
      render(json: @organization) && return
    else
      render json: {errors: @organization.errors}, status: :unprocessable_entity
    end
  end
  def destroy
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage organizations"]}, status: 403
      return
      end
    @organization = Organization.find_by_guid(params[:id])
    if @organization.destroy
      head 204
    else
      render json: {errors: @organization.errors}, status: :unprocessable_entity
    end
  end

private

  def organization_params
    params.permit(:long_name, :short_name, :contact_info, :organization_token)
  end
end

