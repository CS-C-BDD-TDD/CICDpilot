class SettingsController < ApplicationController
  skip_before_filter :check_stix_permission
	
  def current
    render json: Setting.all
  end
end
