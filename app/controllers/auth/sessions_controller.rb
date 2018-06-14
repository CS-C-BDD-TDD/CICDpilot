module Auth
  class SessionsController < ApplicationController
    layout 'auth/application'
    skip_before_filter :check_stix_permission
    skip_before_filter :login_required,only: [:new,:create,:destroy]
    skip_before_filter :password_change, only: [:new,:destroy]
    skip_before_filter :acceptance_required,only: [:new,:create,:destroy]
    skip_before_filter :expired_session?
    skip_before_filter :store_target_location
    before_filter :set_no_cache

    def new
      reset_session
      Thread.new do
        begin
          DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
          Authentication.check_any_expired_accounts
        rescue Exception => e
          DatabasePoolLogging.log_thread_error(e, self.class.to_s, __LINE__)
        ensure
          unless Setting.DATABASE_POOL_ENSURE_THREAD_CONNECTION_CLEARING == false
            begin
              ActiveRecord::Base.clear_active_connections!
            rescue Exception => e
              DatabasePoolLogging.log_thread_error(e, self.class.to_s,
                                                   __LINE__)
            end
          end
        end
        DatabasePoolLogging.log_thread_exit(self.class.to_s, __LINE__)
      end
    end

    def create
      if !Auth::Chain.failure_message.present? && current_user
        redirect_to(root_url)
        return
      end
      if Auth::Chain.failure_message.present?
        message = Auth::Chain.failure_message.is_a?(Array) ? Auth::Chain.failure_message.join(', ') : Auth::Chain.failure_message
        flash[:notice] = "Login failed " + message
      else
        flash[:notice] = "Login failed"
      end

      render :new
    end

    def destroy
      # Make sure you're accessing the real session here.
      # If session.class returns a NullSessionHash, then Rails is protecting the session, and you won't be logged out
      Authentication.logout!(self)
      redirect_to auth_login_url, :notice => "You have been logged out."
    end

    def update
    end
  end
end
