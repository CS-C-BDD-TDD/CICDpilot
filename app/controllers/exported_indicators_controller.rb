class ExportedIndicatorsController < ApplicationController
  
  def index
    unless ExportedIndicator::EXPORTABLE_SYSTEMS.include?(params[:system])
      render json: {errors: "Unable to load list of Exported Indicators.  No system specified."}, status: :bad_request
      return
    end

    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0

    if params[:q].present?
	    search = Search.exported_indicator_search(params[:q], {
			    column: params[:column],
			    direction: params[:direction],
			    ebt: params[:ebt],
			    iet: params[:iet],
			    indicator_type: params[:indicator_type],
			    observable_type: params[:observable_type],
			    limit: (limit || Sunspot.config.pagination.default_per_page),
			    offset: offset,
			    system: params[:system]
	    })
	    total_count = search.total
	    @exported_indicators = search.results
    else
			params[:observable_type] = params[:observable_type].underscore if params[:observable_type]
	    @exported_indicators = ExportedIndicator.where(system: params[:system])
	    @exported_indicators = @exported_indicators.where(exported_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
	    @exported_indicators = @exported_indicators.with_deleted if params[:show_detasked] && params[:show_detasked] == 'true'
	    @exported_indicators = @exported_indicators.joins(indicator: {observables: params[:observable_type].to_sym}) if params[:observable_type]
	    @exported_indicators = @exported_indicators.joins(:indicator).where(stix_indicators: {indicator_type: params[:indicator_type].to_sym}) if params[:indicator_type]
	    @exported_indicators = apply_sort(@exported_indicators,params)
	    total_count ||= @exported_indicators.count
    end

    @metadata = Metadata.new
    @metadata.total_count = total_count

    respond_to do |format|
      format.any(:html,:json) do
	      @exported_indicators = @exported_indicators.limit(limit).offset(offset) unless params[:q]
        render json: {metadata: @metadata, exported_indicators: @exported_indicators}, locals: {associations: {observables: 'embedded'}}
      end
      format.csv do
        if Setting.CLASSIFICATION
          if params[:observable_type] == 'Domain' || params[:observable_type] == 'domain'
            render "exported_indicators/domains/index"
            Thread.new do
              begin
                DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
                @exported_indicators.each(&:set_to_active)
              rescue Exception => e
                DatabasePoolLogging.log_thread_error(e, self.class.to_s,
                                                     __LINE__)
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
          elsif params[:observable_type] == "EmailMessage" || params[:observable_type] == "email_message"
            render "exported_indicators/email_messages/index"
            Thread.new do
              begin
                DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
                @exported_indicators.each(&:set_to_active)
              rescue Exception => e
                DatabasePoolLogging.log_thread_error(e, self.class.to_s,
                                                     __LINE__)
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
            render json: {metadata: @metadata, exported_indicators: @exported_indicators}, locals: {associations: {observables: 'embedded'}}
          end
        else
          render json: {metadata: @metadata, exported_indicators: @exported_indicators}, locals: {associations: {observables: 'embedded'}}
        end
      end
      format.stix do
        stream = render_to_string(template: "exported_indicators/index.stix")
        send_data(stream, type: "text/xml", filename: "Indicators in #{params[:system].upcase}.xml")
      end
      format.ais do
        stream = render_to_string(template: "exported_indicators/index.ais")
        send_data(stream, type: "text/xml", filename: "Indicators in #{params[:system].upcase}.xml")
      end
    end
  end

  def create
    unless User.has_permission(current_user, 'mark_items_for_export')
      render json: {errors: ["You do not have the ability export indicators"]}, status: 403
      return
    end

    @exported_indicator = ExportedIndicator.new(exported_indicator_params(params))

    if @exported_indicator.save
      render json: @exported_indicator
    else
      render json: {errors: @exported_indicator.errors}, status: :unprocessable_entity
    end
  end

  def bulk_inds
  	# Only permit expected params
  	params.permit(:exported_ind)

  	unless User.has_permission(current_user, 'mark_items_for_export')
      render json: {errors: [" you do not have the ability export indicators"]}, status: 403
      return
    end

    if params[:exported_ind].blank?
      render json: {errors: [" you must select at least 1 Indicator"]}, status: 400
      return
    end

    # count of how many we exported
    exported_num = 0

    # Errors array
    validation_errors = {errors: []}

    # Make sure we actually have something to save.
    if params[:exported_ind].present?
    	# look through each one and save.
    	params[:exported_ind].each do |exp|
		    @exported_indicator = ExportedIndicator.new(exported_indicator_params(exp))

		    if @exported_indicator.save
		    	exported_num += 1
		    else
		    	validation_errors[:errors] << @exported_indicator.indicator.title + " : " + @exported_indicator.errors.full_messages.to_sentence if @exported_indicator.indicator.present?
		    end
    	end
	end

	render json: {base: "Exported " + exported_num.to_s + "/" + params[:exported_ind].count.to_s + " Indicators.", errors: validation_errors[:errors]}
  end

  def update
	  unless User.has_permission(current_user, 'mark_items_for_export')
		  render json: {errors: ["You do not have the ability export indicators"]}, status: 403
		  return
	  end

	  @exported_indicator = ExportedIndicator.with_deleted.find_by_guid(params[:guid])

	  if @exported_indicator.update(exported_indicator_params(params))
		  render json: @exported_indicator
	  else
		  render json: {errors: @exported_indicator.errors}, status: :unprocessable_entity
	  end
  end

  def destroy
    unless User.has_permission(current_user, 'mark_items_for_export')
      render json: {errors: ["You do not have the ability retire indicators"]}, status: 403
      return
    end
		Audit.justification = params[:justification]
    @exported_indicator = ExportedIndicator.find_by_guid(params[:id])
    if @exported_indicator.delete
			@exported_indicator.reload
      render json: {success: 'Exported Indicator Retired', exported_indicator: @exported_indicator}
    else
      render json: {errors: "Unable to Delete #{@exported_indicator.guid}"}, status: :unprocessable_entity
    end
  end

  private

  def exported_indicator_params(obj)
    obj.permit(:system, :indicator_id, :color,:description,:detasked_at,:status)
  end


end
