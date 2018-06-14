module Tou
  class AcceptanceController < ApplicationController
    layout 'tou/application'
    skip_before_filter :check_stix_permission
    skip_before_filter :acceptance_required,only:[:new,:create]
    skip_before_filter :store_target_location

    def new
    end
    def create
      current_user.terms_accepted_at = Time.now
      current_user.save
      ::TOULogger.debug("[AcceptanceController::create] user: #{current_user.username} has accepted the terms.")
      redirect_to root_url
    end

  end
end
