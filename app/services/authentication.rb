class Authentication

  ALLOWED_LOGIN_ATTEMPTS = 3

  def initialize
    clear
  end

  class << self
    def logout!(controller)
      user = controller.current_user
      controller.reset_session
      if user
        AuthenticationLogger.debug("[logout] username: #{user.username}")
        Logging::AuthenticationLog.create(
            info: "[logout] username: #{user.username}",
            event: 'logout',
            user: user,
            access_mode: controller.session[:access_mode]
        )
      end
    end
  end

  def set_credentials(login, password)
    clear
    user = User.find_by_username(login)
    unless user
      if login.present?
        AuthenticationLogger.debug("[invalid_username_or_password] attempted with username: #{login}")
        Logging::AuthenticationLog.create(
            info: "[invalid_username_or_password] attempted with username: #{login}",
            event: 'set_credentials',
            access_mode: 'basic'
        )
      end
      @errors << "Invalid username or password"
      return
    end
    @user = user

    if @user.machine
      AuthenticationLogger.debug("PE attempt to login as NPE user #{login}")
      Logging::AuthenticationLog.create(
          info: "PE attempt to login as NPE user #{login}",
          event: 'set_credentials',
          user: @user,
          access_mode: 'basic'
      )
      @errors << "Invalid username"
      unless Setting.SSO_AD
        log_failed_login
      end
      return
    end

    if !@user.correct_password?(password)
      @user.reload
      #if @user.locked?
      #  AuthenticationLogger.info("[locked] username: #{@user.username}")
      #  @errors << "#{@user.username} is locked"
      #  return
      #end
      AuthenticationLogger.debug("[invalid_username_or_password] attempted with username: #{login}")
      Logging::AuthenticationLog.create(
          info: "[invalid_username_or_password] attempted with username: #{login}",
          event: 'set_credentials',
          user: @user,
          access_mode: 'basic'
      )
      @errors << "Invalid username or password."
      unless Setting.SSO_AD
        log_failed_login
      end
      return
    end

    check_account_status
  end

  class APIAuth
    class << self
      def authenticate(api_key, api_key_hash)
        user = User.find_by_api_key(api_key)
        return false unless user
        crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base)
        return false if user.api_key_secret_encrypted.blank?
        actual_api_key_hash = calculate_api_key_hash(user.api_key, crypt.decrypt_and_verify(user.api_key_secret_encrypted))
        return user if api_key_hash == actual_api_key_hash
        return false
      end

      def calculate_api_key_hash(api_key, api_key_secret)
        return Digest::SHA256.hexdigest("#{api_key}@#{api_key_secret}")
      end
    end
  end

  def set_api_credentials(api_key, api_key_hash)
    clear
    @user = Authentication::APIAuth.authenticate(api_key,api_key_hash)
    if !@user
      AuthenticationLogger.debug("[invalid_api_key_or_api_key_hash] attempted with api_key: #{api_key}")
      Logging::AuthenticationLog.create(
          info: "[invalid_api_key_or_api_key_hash] attempted with api_key: #{api_key}",
          event: 'set_api_credentials',
          user: @user,
          access_mode: 'api'
      )
      @errors << "Invalid API Key or API Key Hash"
      return
    end
    check_account_status
  end

  # used for sso login only
  def set_trusted_username(username)
    @user = User.find_by_username(username)
    if !@user
      AuthenticationLogger.debug("[invalid_user] username: #{username}")
      Logging::AuthenticationLog.create(
          info: "[invalid_user] username: #{username}",
          event: 'set_trusted_username',
          user: @user,
          access_mode: "active_directory"
      )
      @errors << "No registered indicators user with username of #{username}"
      return
    end
    check_account_status
  end

  def set_remote_guid(remote_guid)
    if @user.remote_guid.blank?
      AuthenticationLogger.debug("[initial guid assignment] username: #{@user.username} => guid: #{remote_guid}")
      @user.remote_guid = remote_guid
      @user.save
      return;
    end

    if remote_guid != @user.remote_guid 
      #fail user is in conflict
    end

    if @user.remote_guid == @user.remote_guid
      #do nothing
    end

    #fail

  end

  def check_account_status
    if @user.disabled_at.present?
      AuthenticationLogger.debug("[disabled] username: #{@user.username} attempted login")
      Logging::AuthenticationLog.create(
          info: "[disabled] username: #{@user.username} attempted login",
          event: 'check_account_status',
          user: @user
      )
      @errors << "#{@user.username} is disabled"
      return
    end
    if @user.expired?
      AuthenticationLogger.debug("[expired] username: #{@user.username} attempted login")
      Logging::AuthenticationLog.create(
          info: "[expired] username: #{@user.username} attempted login",
          event: 'check_account_status',
          user: @user
      )
      @errors <<  "#{@user.username} is expired"
      return
    end
  end

  def self.check_any_expired_accounts
    User.where("logged_in_at < ?",30.days.ago).where.not(logged_in_at: nil).each do |u|
        u.update_column(:expired_at, u.logged_in_at+30.days)
        AuthenticationLogger.info("[expired] username: #{u.username} is now expired")
        Logging::AuthenticationLog.create(
            info: "[expired] username: #{u.username} is now expired",
            event: 'expired',
            user: u
        )
    end
  end

  def set_user(u)
    clear
    @user = u
    check_account_status
  end

  def get_user
    @user
  end

  def can_login?
    return false unless @user
    return false if @errors.any?
    true
  end

  def error_messages
    @errors
  end

  def log_failed_login
    return if Setting.SSO_AD
    password_reset = Logging::AuthenticationLog.where(user_guid: @user.guid).where("info LIKE ?","%password_reset_by_admin%").where("created_at > ?",15.minutes.ago).order("created_at desc").first
    last_good_login = Logging::AuthenticationLog.where(user_guid: @user.guid).where(:event=>"login").where("created_at > ?",15.minutes.ago).order("created_at desc").first
    time_to_check = 15.minutes.ago
    if password_reset
      time_to_check = password_reset.created_at
    end
    if last_good_login && last_good_login.created_at > time_to_check
      time_to_check = last_good_login.created_at
    end
    failed_logins = Logging::AuthenticationLog.where(user_guid: @user.guid).where("info LIKE ?","%invalid_username_or_password%").where("created_at > ?",time_to_check)

    if failed_logins.count >= ALLOWED_LOGIN_ATTEMPTS
      @user.disabled_at = Time.now
      @user.save
      @errors << "Failed authentication too many times.  #{@user.username} has been disabled."
    end
  end

  private

  def clear
    @user = nil
    @errors = []
  end
end
