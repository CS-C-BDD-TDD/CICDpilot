class ClassificationsController < ApplicationController
  def index
  end

  def validate_classification
    classification_errors = Classification.check_classifications(params)
    
    if classification_errors.blank?
      render json: {success: "All Good!"}
    else
      render json: {errors: classification_errors}, status: 400
    end
  end

end
