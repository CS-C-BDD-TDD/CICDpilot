class ObservablesController < ApplicationController

  def create
    if !User.has_permission(current_user, 'create_indicator_observable')
      render json: {errors: ["You do not have the ability to create observables"]}, status: 403
      return
    end

    @observable = Observable.new(observable_params)
    if @observable.save
      @observable.indicator.solr_index! if @observable.indicator.present?
      render "observables/show.json.rabl"


      is_public_release = (@observable.indicator||Indicator.new).public_release

      if !is_public_release
        return
      end        

      Thread.new do
        begin
          DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
          object = @observable.object.dup
          object_class = object.class
          repl_type = object.class.name.pluralize.underscore

          observable_replications = Replication.where repl_type: 'observables'
          indicator_replications = Replication.where repl_type: 'indicators'
          object_replications = Replication.where repl_type: repl_type

          indicator = @observable.indicator.dup
          indicator_replications.map do |replication|
            replication.send_data indicator.to_json
          end

          replicated_json = object_replications.map do |replication|

            id = if object.respond_to?(:cybox_hash)
              object.cybox_hash
            else
              object.cybox_object_id
            end

            get = replication.dup
            url = get.url
            uri = URI.parse url
            uri.path = uri.path + '/' + id
            get.url = uri.to_s
            json = get.get()

            if get.success?
              begin
              replication.skip
              json.delete("indicators")
              json.delete("audits")
              json
              rescue Exception => e
                ExceptionLogger.info("JSON Parse Error: #{e} : #{json}")
              {}
              end
            else
              replication.send_data object.repl_params.to_json
              {}
            end
          end

          observable_replications_with_replicated_json = observable_replications.zip replicated_json
          observable_replications_with_object = observable_replications_with_replicated_json.map do |replication,json|
            [replication,object.class.new(json)]
          end

          observable_replications_with_object.each do |replication,object|
            observable = @observable.dup
            if (object.cybox_object_id && observable.cybox_object_id == observable.cybox_object_id)
              observable.remote_object_id = object.cybox_object_id
            end
            replication.send_data observable.to_json
          end
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
      end #Thread
    else
      render json: {errors: @observable.errors}, status: :unprocessable_entity
    end
  end

  def destroy
    @observable = Observable.find_by_cybox_object_id(params[:id])

    if !Permissions.can_be_deleted_by(current_user, @observable.indicator)
      render json: {errors: ["You do not have the ability to delete this observable"]}, status: 403
      return
    end

    if !Permissions.can_be_modified_by(current_user, @observable.indicator)
      render json: {errors: ["You do not have the ability to modify this indicator"]}, status: 403
      return
    end

    Audit.justification = params[:justification]
    indicator = @observable.indicator
    if @observable && @observable.destroy
      # Update the indicator that this was attached to, or it will continue to show up in the searches
      Sunspot.index(indicator)
      head 204
    else
      render json: {errors: "Unable to remove observable"}, status: :unprocessable_entity
    end
  end

private

  def observable_params
    params.permit(:cybox_object_id, :remote_object_id, :remote_object_type, :stix_indicator_id)
  end

  def validate(observable)
    if observable.valid?
      render("observables/show.json.rabl") && return
    else
      render json: {errors: observable.errors}, status: :unprocessable_entity
    end
  end

end
