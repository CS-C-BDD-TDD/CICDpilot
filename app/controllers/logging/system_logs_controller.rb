class Logging::SystemLogsController < ApplicationController

  def index
    @logs = nil

    # Go to the next second, because for whatever reason, created_at>? acts like created_at>=?
    if params[:ebt].present? && params[:iet].present?
      params[:ebt]=params[:ebt] + 1.second
      @logs = Logging::SystemLog.where(created_at: params[:ebt]..params[:iet])
    elsif params[:ebt].present?
      params[:ebt]=DateTime.parse(params[:ebt]) + 1.second
      @logs = Logging::SystemLog.where('created_at > ?',params[:ebt])
    end

    render("system_log/index.json.rabl")
  end

  def create
    begin
      @log = Logging::SystemLog.create(log_params)
      system_logs_with_errors =
          Logging::SystemLog.validate_system_logs([@log], true)
    rescue Exception => e
      render json: {errors: e.message.to_s}, status: :unprocessable_entity
      return
    end
    if @log.present?
      if system_logs_with_errors.empty?
        render('system_log/show.json.rabl')
        # We only need to replicate on ECIS to ciap
        if @log.ais_statistic.present? && AppUtilities.is_ecis?
          ReplicationUtilities.replicate_ais_statistics(@log.ais_statistic, 'ais_statistic_forward')
        end
      else
        render json: {errors: @log.errors}, status: :unprocessable_entity
      end
    else
      render json: {
          errors: ['Empty POST request received without a System Log.']
      }, status: :unprocessable_entity
    end
  end

  private

  def log_params
    params.permit(:stix_package_id, :sanitized_package_id, :timestamp, :source, :log_level, :message, :text)
  end

end
