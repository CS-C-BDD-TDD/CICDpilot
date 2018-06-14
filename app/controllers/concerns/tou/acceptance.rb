module TOU
  module Acceptance

    def self.included(controller)

    end

    def acceptance_required
      if !current_user
        ::TOULogger.debug("[TOS::Acceptance#acceptance_required] Attempt to access Terms of Use without a user context.")
      end

      return if request.headers['HTTP_AUTH_MODE'] == 'api'
      return if current_user.machine
      if !current_user.terms_accepted_at?
        ::TOULogger.debug("[TOS::Acceptance#acceptance_required] user: #{current_user.username} has not accepted the terms of use.")
        respond_to do |format|
          format.json do
            render json: {errors: ['You must first accept the terms of use.']},status: :locked
          end
          format.html do
            redirect_to tou_acceptance_url
          end
        end
      end
    end
  end
end
