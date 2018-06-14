class UsersController < ApplicationController
  layout 'auth/application', only: [:new_password]
  skip_before_filter :check_stix_permission
  skip_before_filter :password_change, only: [:new_password,:change_password]
  skip_before_filter :acceptance_required, only: [:new_password,:change_password]
  before_filter :isa_params, only: [:create,:update]

  def index
    if !User.has_permission(current_user, 'view_user_organization')
      render json: {errors: ["You do not have the ability to view users"]}, status: 403
      return
    end

    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    @users = User.includes(:groups,:organization)
    @users = @users.find(params[:ids]) if params[:ids]
    @users ||= User.all
    
    total_count ||= @users.count
    @users = @users.limit(limit).offset(offset)

    @metadata = Metadata.new
    @metadata.total_count = total_count

    render json: {metadata: @metadata, users: @users}, locals: {associations: {organization: 'embedded'}}

  end
  def show
    @user = User.find(params[:id])
    if !User.has_permission(current_user, 'view_user_organization') && @user.username!=current_user.username
      render json: {errors: ["You do not have the ability to view users"]}, status: 403
      return
    end
    render json: @user
  end
  def current
    if current_user.present?
      @user = current_user
      render json: @user, locals: {associations: {audits: 'none'}}
    else
      render json: {errors: ["No user currently logged in"]}, status: 401
    end
  end
  def create
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage users"]}, status: 403
      return
    end
    @user = User.new(user_params(params))
    if @user.save
      render json: @user
    else
      render json: {errors: @user.errors}, status: :unprocessable_entity
    end
  end

  def change_password
    if (User.current_user.id != (params[:id]||"-1").to_i)
      render json: {errors: ["You do not have the ability to manage users"]}, status: 403
      return
    end

    if params[:password].length < 1 && params[:password] == params[:password_confirmation]
      render json: {errors: ["Password must be non-zero length"]},status: 422
      return
    end
    u_params = params.permit(:password,:password_confirmation,:old_password)

    @user = User.find(params[:id])

    unless @user.correct_password? params[:old_password]
	    respond_to do |format|
		    format.json { render json: {errors: {old_password: ["Incorrect Old Password"]}}, status: 403 }
		    format.html do
			    flash[:error] = "Incorrect Old Password"
			    redirect_to new_password_path(@user)
		    end
	    end
	    return
    end

    @user.update_attributes(u_params)

    if @user.valid?
      respond_to do |format|
        format.json do
          render json: @user, locals: {associations: {audits: 'none'}}
        end
        format.html do
          redirect_to root_url
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {errors: @user.errors},status: :unprocessable_entity
        end
        format.html do
          flash[:error] = @user.errors.full_messages.join(', ')
          redirect_to new_password_path(@user)
        end
      end
    end
  end

  def update
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage users"]}, status: 403
      return
    end

    @user = User.find(params[:id]).tap{|s| s.update_attributes(user_params(params))}
    validate(@user)
  end

  def bulk_add_to_group
    # only permit what we know we need.
    params.permit(:user_ids, :group_ids)

    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage users"]}, status: 403
      return
    end

    # keep track of how many users we added to so we can give back a meaningful message
    added_to_users = 0

    # errors array
    validation_errors = {errors: []}

    params[:user_ids].each do |user|
      @user = User.find(user)

      if params[:group_ids].present?
        to_add_groups = params[:group_ids] - @user.group_ids

        if to_add_groups.present?
          begin
            @user.group_ids = @user.group_ids.concat(to_add_groups)
            added_to_users += 1
          rescue Exception => e
            validation_errors[:errors] << @user.username + " : " + e.to_s
          end

          if !@user.valid?
            validation_errors[:errors] << @user.username + " : " + @user.errors
          end
        else
          validation_errors[:errors] << @user.username + " : No Groups to Add."
        end
      else
        validation_errors[:errors] << @user.username + " : No Groups Selected."
      end
    end

    render json: {base: "Successfully added " + params[:group_ids].count.to_s + " Group(s) to " + added_to_users.to_s + "/" + params[:user_ids].count.to_s + " User(s).", errors: validation_errors[:errors]}
  end

  def generate_api_key
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage users"]}, status: 403
      return
    end
    user = current_user
    user = User.find_by_guid(params[:user_guid]) if params[:user_guid]
    if user.nil?
      render json: {errors: ["Could not find user"]}, status: 404
      return
    end
    result = user.generate_api_key
    if result
      render json: {api_key: user.api_key}, status: 201
    else
      render json: {errors: ["Could not add api key to user"]}, status: 400
    end
  end
  def revoke_api_key
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to revoke and API key"]}, status: 403
      return
    end
    user = User.find_by_guid(params[:user_guid]) if params[:user_guid]
    if user.nil?
      render json: {errors: ["Could not find user"]}, status: 404
      return
    end
    result = user.revoke_api_key
    if result
      render json: {}, status: 200
    else
      render json: {errors: ["Could not revoke api key from user"]}, status: 400
    end
  end
  def change_api_key_secret
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage users"]}, status: 403
      return
    end
    user = current_user
    user = User.find_by_guid(params[:user_guid]) if params[:user_guid]
    if user.nil?
      render json: {errors: ["Could not find user"]}, status: 404
      return
    end
    result = user.change_api_key_secret(params[:secret])
    if result
      render json: {api_key: user.api_key}, status: 200
    else
      render json: {errors: ["Could not change user's api key secret"]}, status: 400
    end
  end
  def enable_disable
    Audit.justification = params[:justification]
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage users"]}, status: 403
      return
    end
    user = User.find(params[:user_id]) if params[:user_id]
    if user.nil?
      render json: {errors: ['Could not find user']}, status: 404
      return
    end
    result = user.enable_disable
    if result
      if user.disabled_at.present?
        render json: {status: :disabled}, status: 200
      else
        render json: {status: :enabled}, status: 200
      end
    else
      render json: {errors: user.errors}, status: 400
    end
  end
  def destroy
    if !User.has_permission(current_user, 'create_modify_user_organization')
      render json: {errors: ["You do not have the ability to manage users"]}, status: 403
      return
    end
    @user = User.find(params[:id])
    if @user.destroy
      head 204
    else
      render json: {errors: ["Could not remove user"]}
    end
  end

  def new_password

  end

private

  def isa_params
    return unless params[:isa_entity_cache_attributes].present?

    if params[:isa_entity_cache_attributes][:access_groups].is_a?(Array)
      params[:isa_entity_cache_attributes][:access_groups] = params[:isa_entity_cache_attributes][:access_groups].join(",")
    end
  end

  def user_params(obj)
    obj[:group_ids] ||= []
    obj.permit(
        :username,
        :first_name,
        :last_name,
        :email,
        :phone,
        :password,
        :password_confirmation,
        :old_password,
        :organization_guid,
        :group_ids => [],
        :isa_entity_cache_attributes => [
            :id,
            :admin_org,
            :ato_status,
            :clearance,
            :country,
            :access_groups,
            :distinguished_name,
            :duty_org,
            :entity_class,
            :entity_type
        ],
    )
  end

  def validate(user)
    if user.valid?
      @user=user
      render(json: @user) && return
    else
      render json: {errors: user.errors}, status: :unprocessable_entity
    end
  end

end
