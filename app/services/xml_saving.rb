class XmlSaving
  class << self
    # Store an incoming file in the database, returning an OriginalInput object.

    def store_original_file(f, guid, input_category, mime_type, object_id = nil, object_type = nil)
      # If this is an Upload, or if the files mime type starts with 'text/', load as utf-8
      if input_category == 'Upload' || mime_type.match(/^text\//)
        data = File.open(f, "rb:utf-8").read     # As UTF-8
      else
        data = File.open(f, 'rb').read           # As Binary
      end
      store_original_input(data, guid, input_category, mime_type, object_id, object_type)
    end

    def update_original_xml(xml, guid, subcategory, ciap_id_mapping_ids = [])
      oi = OriginalInput.where("uploaded_file_id = ? and input_category <> 'SOURCE'", guid).first
      ActiveRecord::Base.transaction do
        oi.raw_content = xml if xml.present?
        oi.input_sub_category = subcategory
        oi.save
        valid=true
        if ciap_id_mapping_ids.present?
          count=0
          while valid && (count*1000)<ciap_id_mapping_ids.count
            mappings=CiapIdMapping.where(id: ciap_id_mapping_ids[(count*1000)..((count*1000)+999)])
            oi.ciap_id_mappings << mappings
            valid=oi.valid?
            count+=1
          end
          raise ActiveRecord::Rollback unless valid
        end
      end
      oi
    end

    # Update the raw_xml for every original input connected to the passed in
    # UploadedFile that has the category 'Upload'
    def update_uploads_xml(xml, upload_guid)
      first_oi = nil
      
      oi_list = OriginalInput.where("uploaded_file_id = ? and input_category = 'Upload'", upload_guid)
      ActiveRecord::Base.transaction do
        oi_list.each {|oi|
          first_oi = oi if first_oi.nil?
          
          oi.raw_content = xml if xml.present?
          oi.save
        }
      end
      first_oi
    end
    
    # Store raw data in the database, returning an OriginalInput object.

    def store_original_input(data, guid, input_category, mime_type, object_id = nil,
                             object_type = nil, input_sub_category = nil,
                             ciap_id_mapping_ids = [])
      ActiveRecord::Base.transaction do
        oi = OriginalInput.new(uploaded_file_id: guid,
          input_category: input_category, mime_type: mime_type,
          remote_object_id: object_id, remote_object_type: object_type)
        oi.raw_content = data
        oi.input_sub_category = input_sub_category if input_sub_category.present?
        oi.save
        valid=true
        if ciap_id_mapping_ids.present?
          count=0
          while valid && (count*1000)<ciap_id_mapping_ids.count
            mappings=CiapIdMapping.where(id: ciap_id_mapping_ids[(count*1000)..((count*1000)+999)])
            oi.ciap_id_mappings << mappings
            valid=oi.valid?
            count+=1
          end
          raise ActiveRecord::Rollback unless valid
        end
        oi
      end
    end
  end
end
