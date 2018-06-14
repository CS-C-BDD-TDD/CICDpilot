class RegistryValue < ActiveRecord::Base
  self.table_name = "cybox_win_registry_values"

  belongs_to :registry, primary_key: :cybox_object_id, foreign_key: :cybox_object_id
  include Auditable
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Transferable

  CLASSIFICATION_CONTAINED_BY = [:registry]
  
  before_save :set_cybox_hash

  attr_writer :is_upload

  def self.ingest(uploader, obj, parent = nil)
    x = RegistryValue.new
    HumanReview.adjust(obj, uploader)
    x.reg_name = obj.reg_name
    x.reg_value = obj.reg_value
    x.data_condition = obj.data_condition
    x.cybox_object_id = parent.cybox_object_id unless parent.blank? || parent.cybox_object_id.blank?
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id # Reset to incoming CYBOX Obj ID
    end

    x
  end

  def is_upload
    if @is_upload.nil?
      false
    else
      @is_upload
    end
  end

  def set_cybox_hash
    fields_array = [self.reg_name,
                    self.reg_value]
    all_fields = String.new
    fields_array.each do |f|
      unless f.nil?
        all_fields += f
      end
    end

    write_attribute(:cybox_hash, CyboxHash.generate(all_fields))
  end

  def set_controlled_structure(sm, cybox_registry_id = nil)
    if sm.present?
      cybox_registry_id ||= self.cybox_object_id

      if cybox_registry_id.blank? && self.registry.present?
        cybox_registry_id = self.registry.cybox_object_id
      end
      sm.controlled_structure ="//cybox:Object[@id='#{cybox_registry_id}']/" +
              'cybox:Properties/WinRegistryKeyObj:Values/' +
              'WinRegistryKeyObj:Value'
      if sm.remote_object_field.present?
        case sm.remote_object_field
          when 'reg_name'
            sm.controlled_structure +=
                "/WinRegistryKeyObj:Name[text()='#{self.reg_name}']/"
          when 'reg_value'
            sm.controlled_structure +=
                "/WinRegistryKeyObj:Data[text()='#{self.reg_value}']/"
          else
            sm.controlled_structure = nil
            return
        end
      else
        sm.controlled_structure +=
            "[WinRegistryKeyObj:Name='#{self.reg_name}' or " +
            "WinRegistryKeyObj:Data='#{self.reg_value}']/"
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
  end

end
