class TransfersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:upload]
  skip_before_filter :set_no_cache, only: [:download]

  # Through this code you will see references to Rails.env.production?
  # I added this because in production (ie., with Tomcat being the web server)
  # the ActionController:Live streaming will work properly.  In our development
  # environments, the Thin web server is a caching web server, and therefore,
  # streaming will not work properly.
  if Rails.env.production?
    include ActionController::Live
  end

  require 'zip'

  class StrictTsv
    attr_reader :io_object
    attr_reader :models
    def initialize(io_object)
      @io_object = io_object

      all_models = Dir[Rails.root.join('app/models/*.rb')].map {|f| File.basename(f, '.*').camelize.constantize }
      @models = {}
      all_models.each do |model|
        if model.superclass==ActiveRecord::Base && model.included_modules.include?(Transferable)
          @models[model.table_name]=model
        end
      end
    end

    def parse
      headers = io_object.gets.strip.split("\t")
      io_object.each do |line|
        myline=line
        while myline.scan(/\t/).count != headers.count-1
          myline+=io_object.gets
        end
        fields = Hash[headers.zip(myline.chomp.split("\t",headers.count))]
        fields.keys.each do |key|
          fields[key].gsub!("<+*((TAB))*+>","\t")
        end
        yield fields
      end
    end

    def count_lines
      lines=0
      headers = io_object.gets.strip.split("\t")
      io_object.each do |line|
        myline=line
        while myline.scan(/\t/).count != headers.count-1
          myline+=io_object.gets
        end
        lines+=1
      end
      lines
    end

    def model(table_name)
      models[table_name.gsub(/-(data|guid)$/,'')]
    end
  end

  def audit_package(package)
    audit = Audit.basic
    audit.item = package
    audit.audit_type = :bulk_transfer_download
    audit.message = "Package Downloaded for Bulk Transfer"
    audit.user = current_user
    package.audits << audit
  end

  def audit_indicator(indicator)
    audit = Audit.basic
    audit.item = indicator
    audit.audit_type = :bulk_transfer_download
    audit.message = "Indicator Downloaded for Bulk Transfer"
    audit.user = current_user
    indicator.audits << audit
  end

  def create(original_model,model,row)
    begin
      record = model.create(row)
    rescue Exception => e
      TransferErrorLogger.error(e)
      record = nil
    end
    unless record.nil?
      begin
        if original_model.searchable?
          original_model.find(record.id).index
        end
      rescue
        @retry_solr.push({model: original_model.to_s,id: record.id})
      end
    end
    record
  end

  def update(model,record,row)
    begin
      updated_record = record.update(row)
    rescue Exception => e
      TransferErrorLogger.error(e)
      updated_record = nil
    end
    unless updated_record.nil?
      begin
        if model.searchable?
          model.find(record.id).index
        end
      rescue
        @retry_solr.push({model: model.to_s,id: record.id})
      end
    end
    updated_record
  end

  def download
    @errors=[]
    if !User.has_permission(User.current_user, 'download_for_transfer')
      render json: {errors: ["User does not have permission to view this page"]}, status: :unprocessable_entity
    elsif params[:download].present? && Rails.env.production?
      data = Download.find_by_user_guid(User.current_user.guid)
      if data
        send_data(data.download, type: "application/zip", filename: "ciap_data.zip")
        data.delete
      else
        render json: {errors: ["No download file exists"]}, status: :unprocessable_entity
      end
    elsif params[:ebt].present? && params[:iet].present?
      begin
        if Rails.env.production?
          response.headers['Content-Type'] = 'text/event-stream'
        end

        # Get the list of models that need to be transferred
        all_models = Dir[Rails.root.join('app/models/*.rb')].map {|f| File.basename(f, '.*').camelize.constantize }
        models = []
        all_models.each do |model|
          if model.superclass==ActiveRecord::Base && model.included_modules.include?(Transferable)
            models.push(model)
          end
        end

        total_records=total_guids=0
        models.each do |model|
          if model==User || model==Organization || model==UserTag || model==SystemTag
            total_records += model.count
          elsif model==Audit
            total_records += model.where("item_type_audited<>'Download' and #{model.updated_at_field} between ? and ?",params[:ebt],params[:iet]).count
          else
            total_records += model.where("#{model.updated_at_field} between ? and ?",params[:ebt],params[:iet]).count
          end
          if model.column_names.include?("read_only") || model.column_names.include?("transfer_from_low")
            total_guids += model.count
          end
        end
        remaining_records=total_records
        remaining_guids=total_guids

        if Rails.env.production?
          response.stream.write "data: Total records: #{total_records}, Total guids: #{total_guids}\n\n"
          response.stream.write "data: Remaining records: #{remaining_records}, Remaining guids: #{remaining_guids}\n\n"
        end

        zip_string=Zip::OutputStream.write_buffer do |zio|
          # Output the data for each table (if the table contains data)
          models.each do |model|
            data_to_write = ""
            filename = "#{model.table_name}-data"
            # We need the entire User, Organization and Tags tables, not restricted by dates
            if model==User || model==Organization || model==UserTag || model==SystemTag
              batch_rows = model.find_in_batches(batch_size: 100)
            elsif model==Audit
              batch_rows = model.where("item_type_audited<>'Download' and #{model.updated_at_field} between ? and ?",params[:ebt],params[:iet]).find_in_batches(batch_size: 100)
            else
              batch_rows = model.where("#{model.updated_at_field} between ? and ?",params[:ebt],params[:iet]).find_in_batches(batch_size: 100)
            end
            batch_rows.each do |rows|
              rows.each do |row|
# Not auditing the move to high any longer...previously this was auditing the
# output to STIX for each file.  This is no longer occurring and the value of
# auditing this is very suspect.  Leaving these in the code as a "just in case"
#
#                if model == StixPackage
#                  audit_package(row)
#                end
#                if model == Indicator
#                  audit_indicator(row)
#                end
                unless data_to_write.length>0
                  data_to_write += model.attribute_names.join("\t") + "\n"
                end
                row.attributes.keys.each do |key|
                  if row[key].class == String && row[key].include?("\t")
                    row[key].gsub!("\t","<+*((TAB))*+>")
                  end
                end
                attributes=row.attributes
                if ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'oracle_enhanced'
                  attributes.keys.each do |key|
                    if attributes[key].class.to_s =~ /(Date|Time)/
                      attributes[key]=attributes[key].strftime("%d-%^b-%Y %H:%M:%S")
                    end
                  end
                end
                data_to_write += attributes.values.join("\t") + "\n"
                remaining_records-=1
              end
              if data_to_write.length>0 && Rails.env.production?
                response.stream.write "data: Remaining records: #{remaining_records}, Remaining guids: #{remaining_guids}\n\n"
              end
            end
            if data_to_write.length>0
              if Rails.env.production?
                response.stream.write "data: Remaining records: #{remaining_records}, Remaining guids: #{remaining_guids}\n\n"
              end
              zio.put_next_entry(filename)
              zio.write data_to_write
            end
          end

          # Output all of the current guids for each table
          models.each do |model|
            if model.column_names.include?("read_only") || model.column_names.include?("transfer_from_low")
              data_to_write = ""
              filename = "#{model.table_name}-guid"
              model.select(:id,:guid).find_in_batches(batch_size: 100) do |guids|
                data_to_write += guids.map{ |g| g.guid }.join("\n") + "\n"
                remaining_guids-=guids.length
                if Rails.env.production?
                  response.stream.write "data: Remaining records: #{remaining_records}, Remaining guids: #{remaining_guids}\n\n"
                end
              end
              if Rails.env.production?
                response.stream.write "data: Remaining records: #{remaining_records}, Remaining guids: #{remaining_guids}\n\n"
              end
              zio.put_next_entry(filename)
              zio.write data_to_write
            end
          end
        end

        if Rails.env.production?
          # If we have a download file from a previous run for this user, delete it first.
          current = Download.find_by_user_guid(User.current_user.guid)
          if current
            current.delete
          end
          Download.create(user_guid:User.current_user.guid,download:zip_string.string)
        else
          send_data(zip_string.string, type: "application/zip", filename: "ciap_data.zip")
        end
      rescue IOError
      ensure
        if Rails.env.production? && @errors.count==0
          response.stream.write "data: close\n\n"
          response.stream.close
        end
      end
    else
      @errors << {"ebt"=>"can't be blank"} if !params[:ebt].present?
      @errors << {"iet"=>"can't be blank"} if !params[:iet].present?
      render json: {errors: @errors}, status: :unprocessable_entity
    end
  end

  def upload
    @retry_solr=[]

    unless User.has_permission(current_user, 'upload_for_transfer')
      render json: {errors: ["You do not have the ability to upload zip files"]}, status: 403
      return
    end

    # If we want to check the mime type we can do this.
    # params[:file].content_type
    # this method ends up getting called in two different execution paths. 
    if !params[:continue] && params[:file]
      if params[:file].tempfile.path.include?('.')
        file_ext = params[:file].tempfile.path[params[:file].tempfile.path.rindex('.')...params[:file].tempfile.path.length]
      else
        file_ext = 'Blank File Type'
      end
          
      unless UploadedFile::BULK_UPLOAD_ACCEPTED_FILE_TYPES.include?(file_ext.downcase)
        render json: {errors: ["Could not upload file, Unaccepted file type (" + file_ext + ")"]}, status: 415
        return
      end
    end

    # If we are not in production "continue" mode, load the file
    if !Rails.env.production? or (Rails.env.production? && !params[:continue])
      body = request.body.read
      request.body.rewind

      if params['file']
        upload = params['file']
      else # An API request
        upload = body
      end

      @uploaded_file = UploadedFile.new
      @uploaded_file.upload_zip_file(upload, current_user.guid, {mime_type: params['file'].content_type})
    end

    # If we're in production, and we're continuing, load the data record.
    # Otherwise, save the record and return, so we can execute the second
    # call to load the data and return the running status
    if Rails.env.production?
      if params[:continue]
        file_record_id = Download.find_by_user_guid(User.current_user.guid)
        if file_record_id
          @uploaded_file = UploadedFile.find(file_record_id.download)
          file_record_id.delete
        else
          render json: {errors: ["No file exists"]}, status: unprocessable_entity
        end
      else
        # If we have a record from a previous run for this user, delete it first.
        current = Download.find_by_user_guid(User.current_user.guid)
        if current
          current.delete
        end
        Download.create(user_guid:User.current_user.guid,download:@uploaded_file.id.to_s)
        render json: {id: @uploaded_file.id}
        return
      end
    end

    # If we've made it here, we are either in development mode, or production in "continue" mode
    begin
      if Rails.env.production?
        response.headers['Content-Type'] = 'text/event-stream'
      end

      # Making a copy of the upload, because somehow, the Zip library modifies it
      file_to_upload = @uploaded_file.original_inputs.first.raw_content

      total_records=total_guids=0
      Zip::File.open_buffer(@uploaded_file.original_inputs.first.raw_content) do |file|
        file.each do |entry|
          if entry.name =~ /-data$/
            tsv = StrictTsv.new(StringIO.new(entry.get_input_stream.read))
            total_records += tsv.count_lines
          else
            upload = entry.get_input_stream.read.split("\n")
            total_guids += upload.count
          end
        end
      end if @uploaded_file.original_inputs.present?

      remaining_records = total_records
      remaining_guids = total_guids
      total_created=total_updated=0
      error_created=error_updated=0

      if Rails.env.production?
        response.stream.write "data: Total records: #{total_records}, Total guids: #{total_guids}\n\n"
        response.stream.write "data: Remaining records: #{remaining_records}, Remaining guids: #{remaining_guids}\n\n"
        response.stream.write "data: Created records: #{total_created}, Updated records: #{total_updated}, Errors creating: #{error_created}, Errors updating: #{error_updated}\n\n"
      end

      Zip::File.open_buffer(file_to_upload) do |file|
        file.each do |entry|
          if entry.name =~ /-data$/
            tsv = StrictTsv.new(StringIO.new(entry.get_input_stream.read))
            model = tsv.model(entry.name)
            has_read_only = model.column_names.include?("read_only")
            has_transfer_from_low = model.column_names.include?("transfer_from_low")
            Object.const_set('M'+model.name, Class.new(ActiveRecord::Base) { self.table_name = model.table_name })
            new_model = ('M'+model.name).constantize
            tsv.parse do |row|
              row.delete('id')
              if has_read_only
                row['read_only'] = "true"
              end
              if has_transfer_from_low
                row['transfer_from_low'] = "true"
              end
              if model==Organization
                # Look to see if an organization with the same GUID exists
                record = new_model.find_by_guid(row['guid'])
                if record.nil?
                  # If we don't find one, append -U to the name, and create it
                  row['short_name'] += '-U'
                  create(model,new_model,row) ? total_created+=1 : error_created+=1
                else
                  # Otherwise, if we have one, and it already has a -U (meaning it transferred
                  # from the low side) then update it.
                  if record.short_name =~ /-U$/
                    row['short_name'] += '-U'
                    update(model,record,row) ? total_updated+=1 : error_updated+=1
                  else
                    total_updated+=1
                  end
                end
                # The reason we do the above is that some organizations are created during
                # system setup and given the same static GUID.  In this case, the organization
                # used will be the same on both.
              elsif model==User
                row['disabled_at']=DateTime.now
                record = new_model.find_by_guid(row['guid'])
                row['username'] += '-u'
                if record.nil?
                  create(model,new_model,row) ? total_created+=1 : error_created+=1
                else
                  update(model,record,row) ? total_updated+=1 : error_updated+=1
                end
              elsif model==UserTag || model==SystemTag
                record = new_model.find_by_guid(row['guid'])
                row['name'] += '-u'
                row['name_normalized'] += '-u'
                if record.nil?
                  create(model,new_model,row) ? total_created+=1 : error_created+=1
                else
                  update(model,record,row) ? total_updated+=1 : error_updated+=1
                end
              elsif model==Audit
                # Audit records never get updated, there will only be new ones
                record = new_model.find_by_guid(row['guid'])
                if record.nil?
                  create(model,new_model,row) ? total_created+=1 : error_created+=1
                else
                  total_updated+=1
                end
              else
                # Get record matching guid, if it exists
                record = new_model.where(guid: row['guid'])
                if has_read_only && !record.empty?
                  # If the model has read_only, get the read_only version, if it exists
                  record = record.where(read_only: true)
                end
                if has_transfer_from_low && !record.empty?
                  # If the model has transfer_from_low, get the transfer_from_low version, if it exists
                  record = record.where(transfer_from_low: true)
                end
                record = record.first
                if record.nil?
                  create(model,new_model,row) ? total_created+=1 : error_created+=1
                else
                  update(model,record,row) ? total_updated+=1 : error_updated+=1
                end
              end
              remaining_records-=1
              if remaining_records % 100 == 0
                response.stream.write "data: Remaining records: #{remaining_records}, Remaining guids: #{remaining_guids}\n\n"
                response.stream.write "data: Created records: #{total_created}, Updated records: #{total_updated}, Errors creating: #{error_created}, Errors updating: #{error_updated}\n\n"
              end
            end
            response.stream.write "data: Remaining records: #{remaining_records}, Remaining guids: #{remaining_guids}\n\n"
            response.stream.write "data: Created records: #{total_created}, Updated records: #{total_updated}, Errors creating: #{error_created}, Errors updating: #{error_updated}\n\n"
            Object.send(:remove_const, 'M'+model.name)
          else
            if entry.name =~ /-guid$/
              guidfile=entry.get_input_stream.read
              tsv = StrictTsv.new(StringIO.new(guidfile))
              model = tsv.model(entry.name)
              has_read_only = model.column_names.include?("read_only")
              has_transfer_from_low = model.column_names.include?("transfer_from_low")
              if has_read_only
                current_guids = model.where(read_only: true).pluck(:guid)
              elsif has_transfer_from_low
                current_guids = model.where(transfer_from_low: true).pluck(:guid)
              end
              guidfile.split("\n").each do |guid|
                current_guids -= [guid]
                remaining_guids -= 1
                if remaining_guids % 100 == 0
                  response.stream.write "data: Remaining records: #{remaining_records}, Remaining guids: #{remaining_guids}\n\n"
                end
              end
              if current_guids.length > 0
                current_guids.each do |guid|
                  if has_read_only
                    model.where("read_only=? and guid=?",true,guid).first.delete
                  elsif has_transfer_from_low
                    model.where("transfer_from_low=? and guid=?",true,guid).first.delete
                  end
                end
              end
              response.stream.write "data: Remaining records: #{remaining_records}, Remaining guids: #{remaining_guids}\n\n"
            end
          end
        end
        # Retry SOLR problems
        @retry_solr.each do |solr|
          begin
            solr[:model].constantize.find(solr[:id]).index
          rescue
            TransferErrorLogger.error("SOLR ERROR: #{solr[:model]} ID: #{solr[:id]}")
          end
        end
        @uploaded_file.zip_status = "Created records: #{total_created}, Updated records: #{total_updated}, Errors creating: #{error_created}, Errors updating: #{error_updated}"
        @uploaded_file.save
      end if @uploaded_file.original_inputs.present?

      if !Rails.env.production?
        if @uploaded_file.status == 'S'
          render json: @uploaded_file, status: 201
        elsif @uploaded_file.status == 'F'
          render json: @uploaded_file, status: 406
        end
      end
    rescue IOError
    ensure
      if Rails.env.production?
        response.stream.write "data: close\n\n"
        response.stream.close
      end
    end
  end
end
