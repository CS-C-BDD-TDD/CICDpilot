class WeatherMapHeatmapsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
#    unless can_view(current_user)
#      render json: {errors: ["You do not have the ability to view heatmaps"]}, status: 403
#      return
#    end
    @heatmaps = WeatherMapImage.order('created_at desc').all

    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    if params[:q].present?
      search = Search.uploads_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (limit || Sunspot.config.pagination.default_per_page),
        offset: offset
      })
      total_count = search.total
      @heatmaps = search.results

      @heatmaps ||= []
    else
      @heatmaps ||= WeatherMapImage.reorder(created_at: :asc)

      @heatmaps = @heatmaps.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @heatmaps = apply_sort(@heatmaps, params)
      total_count = @heatmaps.count
      @heatmaps = @heatmaps.limit(limit).offset(offset)
    end
    render "weather_map_images/index.json.rabl"
  end

  def show
#    unless can_view(current_user)
#      render json: {errors: ["You do not have the ability to view heatmaps"]}, status: 403
#      return
#    end

    num = params[:id].to_i
    if num == 0
      upload = WeatherMapImage.where(:organization_token => params[:id])
                              .order('created_at desc').first
    else
      upload = WeatherMapImage.where(:id => params[:id]).first
    end

    if upload && upload.original_input
      begin
        extension = upload.original_input.mime_type.split("/")[1]
      rescue
        extension = "jpeg"
      end

      send_data(upload.original_input.raw_content,
        :type => upload.original_input.mime_type,
        :filename => "heatmap." + extension,
        :disposition => 'attachment', :status => '200 OK')
    else
      upload = WeatherMapImage.where(:organization_token => 'DEFAULT_HEATMAP')
                              .order('created_at desc').first

      if upload && upload.original_input
        send_data(upload.original_input.raw_content,
          :type => 'image/jpeg',
          :filename => "heatmap.jpg",
          :disposition => 'attachment', :status => '200 OK')
      else
        render json: {errors: ["Could not find heatmap with ID: #{params[:id]}"]}, status: 404
      end
    end
  end

  def create
    unless can_upload_heatmaps(current_user)
      render json: {errors: ["You do not have the ability to create heatmaps"]}, status: 403
      return
    end

    if params['file']            # If we implemented UI for uploading a heatmap
      upload = params['file']
    else                         # An API request(the expected receipt method)
      upload = request.body.read
      request.body.rewind
    end

    @uploaded_file = UploadedFile.new

    org_token = params[:organization_token] || 
                request.headers['organization_token'] ||
                params['organization-token'] ||
                request.headers['organization-token']
    WeatherMapLogger.info("[WeatherHeatMapController][create] Will create heatmap for #{org_token}")

    if @uploaded_file && org_token
      @uploaded_file.upload_weathermap_image(upload, current_user.guid, org_token, {mime_type: request.headers['CONTENT_TYPE']})
      render "weather_map_images/show.json.rabl", status: 201
      replications = Replication.where(repl_type:'heatmap')
      replications.each do |replication|
        if params[:async] == 'true'
          WeatherMapLogger.info("[WeatherHeatMapController][create] params[:async] == true")
          Thread.new do
            begin
              DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
              WeatherMapLogger.info("[WeatherHeatMapController][create][async] Replicating. ID: #{replication.id}, URL: #{replication.url}")
              replication.send_data(upload,{'organization-token'=>org_token,
                                            'Content-type'=>request.env['CONTENT_TYPE']})
              WeatherMapLogger.info("[WeatherHeatMapController][create][async] Done. replication.last_status: #{replication.last_status}")
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
        else
          WeatherMapLogger.info("[WeatherHeatMapController][create][sync] Replicating. ID: #{replication.id}, URL: #{replication.url}")
          replication.send_data(upload,{'organization-token'=>org_token,
                                          'Content-type'=>request.env['CONTENT_TYPE']})
          WeatherMapLogger.info("[WeatherHeatMapController][create][sync] Done. replication.last_status: #{replication.last_status}")
        end
      end
    else
      WeatherMapLogger.info("[WeatherHeatMapController][create] Error. Could not create heatmap.")
      render json: {errors: ["Could not create heatmap"]}, status: 404
    end
  end

  private

#    def can_view(u)
#      User.has_permission(u, 'view_uploaded_file_info')
#    end

    def can_upload_heatmaps(u)
      User.has_permission(u, 'view_uploaded_file_info') &&
      User.has_permission(u, 'create_indicator_observable')
    end

end
