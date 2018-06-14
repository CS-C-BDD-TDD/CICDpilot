class UserSessionController < ApplicationController
  def ping
    sess = UserSession.find_by_session_id(session["session_id"])
    if sess.nil?
      # If the session record has been deleted (because the service has been restarted), create a new record
      UserSession.create!(username: current_user.username,session_id: session[:session_id],session_updated_at: session[:updated_at])
    else
      sess.session_updated_at = session["updated_at"]
      sess.save!
    end
    render json: {}
  end
end
