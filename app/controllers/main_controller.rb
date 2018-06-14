class MainController < ApplicationController
  skip_before_filter :check_stix_permission
  
  def index
    redirect_to :indicators if request.headers['HTTP_AUTH_MODE'] == 'api'
  end

  skip_before_filter :login_required, only: :ping

  def ping
    connection = ActiveRecord::Base.connection
    connection.reconnect!
    render text: 'ACTIVE'
  rescue
    render text: 'INACTIVE'
  end
end
