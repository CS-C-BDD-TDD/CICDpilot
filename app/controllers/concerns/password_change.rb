module PasswordChange
  #requires user to be logged in and authenticated already
  def password_change
    return if Setting.SSO_AD
		flash.clear
    return if request.headers['HTTP_API_KEY'].presence || params[:api_key]
    return unless current_user.present?

    if current_user.passwords.first.blank?
      redirect_to new_password_path(current_user)
      return
    end

    if current_user.passwords.first.expired?
      respond_to do |format|
        format.json do
          render json: {errors: ["Login Failed: Your password has expired"]}, status: :locked
        end
        format.html do
          redirect_to new_password_path(current_user)
        end
      end
    end
  end

end