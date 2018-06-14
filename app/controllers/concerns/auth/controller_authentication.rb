module Auth
  class RemoteUser
    attr_reader :full_name
    attr_accessor :remote_guid
    def initialize(full_name)
      @full_name = full_name
    end

    def username_normalized
      username.downcase
    end

    def domain_normalized
      domain.downcase
    end

    def username
      @username ||= (self.full_name||'').split('@').first
    end

    def domain
      @domain ||= (self.full_name||'').split('@').last
    end

  end

  class Chain
    attr_reader :controller,:authenticated_with_authenticator

    def self.failure_message
      @failure_message
    end

    def self.failure_message=(failure_message)
      @failure_message = failure_message
    end

    def initialize(controller)
      # @authenticators = []
      @controller = controller
      @authenticated_with_authenticator = nil
    end

    def provide_user
      self.class.failure_message=nil
      Authenticator.all.each do |authenticator_name|
        authenticator_class = authenticator_name.constantize
        authenticator = authenticator_class.new(controller)
        current_user,failure_message = authenticator.attempt_login

        unless failure_message.nil?
          self.class.failure_message=failure_message
        end
        controller.session[:access_mode] = authenticator.request.env['HTTP_AUTH_MODE']
        if current_user
          @authenticated_with_authenticator = authenticator
          current_user.logged_in_at = Time.now
          current_user.save
          return current_user
        end
      end
      return nil
    end

    def check_number_of_sessions
      # Clear out old entries
      UserSession.where("session_updated_at < ?",DateTime.now - 1.minute).delete_all
      user = (self.provide_user||User.new)
      if user.username
        if UserSession.where('username=?',user.username).count>=(Setting.CONCURRENT_LOGINS||3)
          return false
        end
      end
      populate_session!(user)
      true
    end

    def populate_session!(user)
      controller.session[:user_id] = user.id
      controller.session[:created_at] = Time.now
      controller.session[:updated_at] = Time.now
      AuthenticationLogger.debug("[populate_session!] controller.session[:user_id]: #{controller.session[:user_id]}")
      UserSession.create!(username: user.username,session_id: controller.session[:session_id],session_updated_at: controller.session[:updated_at]) if user.username && controller.session[:session_id]
    end
  end

  module Provider
    class Base
      attr_reader :request,:params
      def initialize(controller)
        @request = controller.request
        @params = controller.params
      end
    end

    class ActiveDirectory < Base
      def attempt_login
        remote_user = RemoteUser.new(request.headers['HTTP_REMOTE_USER'])
        auth = Authentication.new
        auth.set_trusted_username(remote_user.username)
        if request.headers['HTTP_REMOTE_USER_GUID'].present?
          remote_user.remote_guid = request.headers['HTTP_REMOTE_USER_GUID']
          auth.set_remote_guid(remote_user.remote_guid)
        end
        request.headers['HTTP_AUTH_MODE'] = 'active_directory'
        return nil,auth.error_messages unless auth.can_login?
        AuthenticationLogger.debug("[login][ActiveDirectory] HTTP_AUTH_MODE: active_directory")
        AuthenticationLogger.debug("[login][ActiveDirectory] username: #{remote_user.username}")
        Logging::AuthenticationLog.create(
            info: "[login][ActiveDirectory] HTTP_AUTH_MODE: active_directory",
            event: 'login',
            user: auth.get_user,
            access_mode: request.headers['HTTP_AUTH_MODE'],
            remote_ip: request.remote_ip
        )
        return auth.get_user,nil
      end
    end

    class Basic < Base
      def attempt_login
        # Check if this is fall through from a failed API authentication
        # attempt so we can skip attempting Basic authentication if that is
        # not the method desired and API authentication clearly already failed.
        return nil,nil if request.headers['HTTP_API_KEY'].presence.present? ||
            request.headers['HTTP_API_KEY_HASH'].presence.present? ||
            params[:api_key].present? || params[:api_key_hash].present?
        auth = Authentication.new
        auth.set_credentials(params[:username],params[:password])
        request.headers['HTTP_AUTH_MODE'] = 'basic'
        return nil,auth.error_messages unless auth.can_login?
        AuthenticationLogger.debug("[login][Basic] HTTP_AUTH_MODE: basic")
        AuthenticationLogger.debug("[login][Basic] username: #{params[:username]}")
        Logging::AuthenticationLog.create(
            info: "[login][Basic] HTTP_AUTH_MODE: basic",
            event: 'login',
            user: auth.get_user,
            access_mode: request.headers['HTTP_AUTH_MODE'],
            remote_ip: request.remote_ip
        )
        return auth.get_user,nil
      end
    end

    class API < Base
      def attempt_login
        api_key ||= request.headers['HTTP_API_KEY'].presence || params[:api_key]
        api_key_hash ||= request.headers['HTTP_API_KEY_HASH'].presence || params[:api_key_hash]

        if api_key.present? || api_key_hash.present?
          request.headers["HTTP_API_REQUEST"] = true
          request.headers['HTTP_AUTH_MODE'] = 'api'
        end

        return nil,nil unless api_key && api_key_hash

        # at this point, an api_key and hash have been passed to us, so I'm going to assume it's an API login attempt
        auth = Authentication.new
        auth.set_api_credentials(api_key, api_key_hash)
        return nil,'You must provide a valid api_key and api_key_hash to perform this action' if !auth.can_login?

        user = auth.get_user
        AuthenticationLogger.debug("[login][API] request.method: #{request.method}")
        Logging::AuthenticationLog.create(
            info: "[login][API] HTTP_AUTH_MODE: api",
            event: 'request.method',
            user: user,
            access_mode: request.headers['HTTP_AUTH_MODE'],
            remote_ip: request.remote_ip
        )

        if request.method == 'PUT' || request.method == 'POST' || request.method == 'DELETE' || request.method == 'PATCH'
          if !user.machine
            AuthenticationLogger.debug("[login][API] user: #{user.username} is not a machine user, but attempted to write.")
            return nil,'You do not have permission to write.'
          end
        end

        AuthenticationLogger.debug("[login][API] HTTP_AUTH_MODE: api")
        AuthenticationLogger.debug("[login][API] api_key: #{api_key}, username: #{auth.get_user.username}")
        Logging::AuthenticationLog.create(
            info: "[login][API] HTTP_AUTH_MODE: api",
            event: request.env["action_controller.instance"].class.to_s + '#' + request.env["action_controller.instance"].action_name,
            user: user,
            access_mode: request.headers['HTTP_AUTH_MODE'],
            remote_ip: request.remote_ip
        )
        return user,nil
      end
    end
  end

  module ControllerAuthentication
    def self.included(controller)
      controller.send :helper_method,:redirect_to_target_or_default
      controller.send :helper_method,:current_user
    end

    def login_required
      # Get the current_user by the appropriate method for the authentication
      # method, assign to the current_login_user local variable, and then
      # proceed as before the special handling for API authentication.
      current_login_user = nil
      if request.headers['HTTP_API_KEY'].presence.present? ||
          params[:api_key].present? || session[:access_mode] == 'api'
        # Ignore any current session information from the cookie-based session
        # store and force re-authentication to get the current user for API
        # authentication.
        us=UserSession.find_by_session_id(session[:session_id])
        unless us.nil?
          us.delete
        end
        reset_session
        current_login_user = current_user(true)
      else
        current_login_user = current_user
      end
      if current_login_user.present?
        User.current_user = current_login_user
      else
        AuthenticationLogger.debug("[login_required] current_user is not set.")
        AuthenticationLogger.debug("[login_required] HTTP_AUTH_MODE: #{request.headers['HTTP_AUTH_MODE']}")
        Logging::AuthenticationLog.create(
            info: "[login_required] HTTP_AUTH_MODE: #{request.headers['HTTP_AUTH_MODE']}",
            event: 'login_required',
            access_mode: request.session[:access_mode],
            remote_ip: request.remote_ip
        )

        case request.headers['HTTP_AUTH_MODE']
          when 'api'
            failure_message = Auth::Chain.failure_message || "You must provide a valid api_key and api_key_hash to perform this action"
            render json: {errors: [failure_message]}, status: 401
          when 'active_directory'
            render file: '401.html',layout: false
          when 'basic'
            respond_to do |format|
              format.any(:html,:stix,:csv) do
                failure_message = Auth::Chain.failure_message || "You must first log in before accessing this page."
                redirect_to auth_login_url,alert: failure_message
              end
              format.json do
                failure_message = Auth::Chain.failure_message || "Your session is no longer active."
                render json: {errors: [failure_message]}, status: 401
              end
            end
          else
            respond_to do |format|
              format.any(:html,:stix,:csv) do
                failure_message = Auth::Chain.failure_message || "You must first log in before accessing this page."
                redirect_to auth_login_url,alert: failure_message
              end
              format.json do
                failure_message = Auth::Chain.failure_message || "Your session is no longer active."
                render json: {errors: [failure_message]}, status: 401
              end
            end
        end
      end
    end

    def is_api_key_request?
      return session[:access_mode] == 'api'
    end

    def can_request_write?
      # If UI or (API && machine user)
      return !is_api_key_request? || (is_api_key_request? && current_user.machine)
    end

    def should_user_be_throttled?
      # If UI or (API && not machine user)
      return !is_api_key_request? || (is_api_key_request? && !current_user.machine)
    end

    def redirect_to_target_or_default(default,*args)
      redirect_to(session[:return_to]||default,*args)
      session[:return_to] = nil
    end

    def current_user(ignore_current_session=false)
      # If the ignore_current_session parameter is true, ignore any current
      # session information from the cookie-based session store and force
      # re-authentication to get the current user.
      if session[:user_id] && !ignore_current_session
        @current_user ||= User.where(id: session[:user_id]).first
        return @current_user
      end
      @chain ||= Auth::Chain.new(self)
      if @chain.check_number_of_sessions
        @current_user ||= User.where(id: session[:user_id]).first
        return @current_user
      else
        if UserSession.find_by_session_id(session[:session_id])
          UserSession.find_by_session_id(session[:session_id]).delete
        end
        flash['error']="You are already logged in the maximum number of times (#{(Setting.CONCURRENT_LOGINS||3)}) that are allowed.  If you believe this is not the case try again in 60 seconds."
        render 'auth/sessions/new',layout: 'auth/application', status: 401
        return
      end
    end

    def expired_session?
      return unless session.present?

      if session[:created_at].blank? || session[:updated_at].blank? || session[:updated_at].to_datetime < 1.hour.ago
        if session[:access_mode] == 'active_directory'
          cookies[:error_message] = "Your session has expired, your session will be recreated before your request is processed"
          @chain ||= Auth::Chain.new(self)
          unless @chain.check_number_of_sessions
            if UserSession.find_by_session_id(session[:session_id])
              UserSession.find_by_session_id(session[:session_id]).delete
            end
            flash['error']="You are already logged in the maximum number of times (#{(Setting.CONCURRENT_LOGINS||3)}) that are allowed.  If you believe this is not the case try again in 60 seconds."
            render 'auth/sessions/new',layout: 'auth/application', status: 401
          end
        else
          Authentication.logout!(self)
          flash['error'] = "Your session has expired, you have been logged out."

          if request.path.include?('#')
            render nothing: true, status: 401
          else
            render 'auth/sessions/new',layout: 'auth/application', :notice => "Your session has expired, you have been logged out.", status: 401
          end
        end
      else
        session[:updated_at] = Time.now
        cookies.delete :error_message if cookies[:error_message].present?
      end
    end
  end
end
