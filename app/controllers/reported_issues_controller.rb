class ReportedIssuesController < ApplicationController
  skip_before_filter :check_stix_permission
  
  def create
    @issue = ReportedIssue.create(issue_params)
    if @issue.valid?
      render "reported_issues/create.json.rabl"
      return
    else
      render json: {errors: @issue.errors}, status: :unprocessable_entity
    end
  end

private

  def issue_params
    params.permit(:subject,:description,:called_from)
  end

end
