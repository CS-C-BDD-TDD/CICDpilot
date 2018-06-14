class EmailFilesController < ApplicationController
  
  def update
    email = EmailMessage.find_by_cybox_object_id(params[:id])
    id_map = Hash.new
    email.cybox_files.each do |f|
      id_map[f.cybox_object_id] = f.guid
    end

    current_cybox_object_ids = email.cybox_files.map { |f| f.cybox_object_id }
    updated_cybox_object_ids = params[:cybox_object_ids]

    if params[:new] == true
      id_to_be_linked = (params[:cybox_object_ids] - current_cybox_object_ids)[0]
      obj = CyboxFile.find_by_cybox_object_id(id_to_be_linked)
      if obj.present? && email.portion_marking.present? && obj.portion_marking.present? && Classification::CLASSIFICATIONS.index(email.portion_marking) < Classification::CLASSIFICATIONS.index(obj.portion_marking)
        render json: {errors: ["Invalid Classification, Classification of the Email Message is less than the classification of the contained File objects"]}, status: 403
        return
      end
    end

    delete_array = []
    add_array = []

    current_cybox_object_ids.each do |c|
      unless updated_cybox_object_ids.include? c
        delete_array.push(c)
      end
    end

    updated_cybox_object_ids.each do |c|
      unless current_cybox_object_ids.include? c
        add_array.push(c)
      end
    end

    transaction_status = nil

    changes=""

    if delete_array.count>0 or add_array.count>0
      # Start a transaction, because if ANY of this fails, we need to fail
      ActiveRecord::Base.transaction do
        delete_array.each do |f|
          file=CyboxFile.find_by_cybox_object_id(f)
          changes+="Cybox file #{file.cybox_object_id} removed "
          transaction_status = EmailFile.where("email_message_id=? and cybox_file_id=?",email.guid,id_map[f])[0].delete
          raise ActiveRecord::Rollback unless transaction_status
        end
        add_array.each do |f|
          file=CyboxFile.find_by_cybox_object_id(f)
          changes+="Cybox file #{file.cybox_object_id} added "
          transaction_status = EmailFile.create(:email_message_id => email.guid,:cybox_file_id => file.guid)
          raise ActiveRecord::Rollback unless transaction_status
        end
      end
    end

    if transaction_status
      # Update email audit
      audit = Audit.basic
      audit.message = "Email observable updated"
      audit.details = changes
      audit.item = email
      audit.audit_type = :email_attachments_update
      email.audits << audit

      # Update indicator audit
      email.indicators.each do |i|
        audit = Audit.basic
        audit.message = "Email observable updated"
        audit.details = changes
        audit.item = i
        audit.audit_type = :email_attachments_update
        i.audits << audit
        i.updated_at = Time.now
        i.save
      end
    end

    if transaction_status==false
      render json: {}, status: :unprocessible_entity
    else
      render json: {audits: email.audits}, status: 201
    end
  end
end
