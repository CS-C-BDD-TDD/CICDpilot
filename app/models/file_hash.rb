class FileHash < ActiveRecord::Base
  module RawAttribute
    module Writers
      def simple_hash_value=(value)
        return unless value
        write_attribute(:simple_hash_value,value)
        write_attribute(:simple_hash_value_normalized,value.upcase)
      end
      def fuzzy_hash_value=(value)
        return unless value
        write_attribute(:fuzzy_hash_value,value)
        write_attribute(:fuzzy_hash_value_normalized,value.upcase)
      end
    end
  end

  module Validations
    def self.included(base)
      base.instance_eval do
        validates_presence_of :simple_hash_value, :if => lambda {self.hash_type=='MD5' or self.hash_type=='SHA1' or self.hash_type=='SHA256'}
        validates_presence_of :fuzzy_hash_value, :if => lambda {self.hash_type=='SSDEEP'}
      end
    end
  end

  self.table_name = "cybox_file_hashes"
  belongs_to :file,  class_name: 'CyboxFile', primary_key: :cybox_object_id, foreign_key: :cybox_file_id
  include Auditable
  include FileHash::Validations
  include FileHash::RawAttribute::Writers
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Transferable

  CLASSIFICATION_CONTAINED_BY = [:file]
  SIMPLE_HASHES = %w(MD5 SHA1 SHA224 SHA256)

  before_validation :infer_hash_type
  
  validate :validate_hashes
  validates_presence_of :hash_type
 

  def self.ingest(uploader, obj, parent = nil)
    x = FileHash.new
    HumanReview.adjust(obj, uploader)
    #x.apply_condition = obj.apply_condition
    x.cybox_file_id = parent.cybox_object_id unless parent.blank? || parent.cybox_object_id.blank?
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    if obj.fuzzy_hash_value.present?
      x.fuzzy_hash_value = obj.fuzzy_hash_value
    end
    x.hash_condition = obj.name_condition
    x.hash_type = obj.type.upcase
    if obj.simple_hash_value.present?
      x.simple_hash_value = obj.simple_hash_value
    end

    if x.simple_hash_value.present? && !SIMPLE_HASHES.include?(x.hash_type)
      IngestUtilities.add_warning(uploader,"Skipping File Hash of #{x.simple_hash_value}, Hash Type #{x.hash_type} is unsupported")
    end

    x
  end

  def set_cybox_hash
    hash_type = self.hash_type
    value = ""
    if (value == 'MD5' or value == 'SHA1' or value == 'SHA256' || value=='SHA224')
      value = self.simple_hash_value_normalized
    elsif self.fuzzy_hash_value_normalized.present?
      value = self.fuzzy_hash_value_normalized
    end
    write_attribute(:cybox_hash, CyboxHash.generate(hash_type + value)) if value.present?
  end

  def set_controlled_structure(sm, cybox_file_id = nil)
    if sm.present?
      cybox_file_id ||= self.cybox_file_id

      if cybox_file_id.blank? && self.file.present?
        cybox_file_id = self.file.cybox_object_id
      end
      sm.controlled_structure =
          "//cybox:Object[@id='#{cybox_file_id}']/" +
              'cybox:Properties/FileObj:Hashes/cyboxCommon:Hash' +
              "[cyboxCommon:Type='#{self.hash_type}']/"
      if sm.remote_object_field.present?
        case sm.remote_object_field
          when 'simple_hash_value_normalized'
            sm.controlled_structure +=
                'cyboxCommon:Simple_Hash_Value/'
          when 'fuzzy_hash_value_normalized'
            sm.controlled_structure +=
                'cyboxCommon:Fuzzy_Hash_Value/'
          else
            sm.controlled_structure = nil
            return
        end
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
  end

  private

  def infer_hash_type
    return unless self.simple_hash_value_normalized.present? || self.fuzzy_hash_value_normalized.present?

    if self.fuzzy_hash_value_normalized.present?
      write_attribute(:hash_type, 'SSDEEP')
      return
    end

    if self.simple_hash_value_normalized.present?
      return unless /^[0-9A-F]+$/i === self.simple_hash_value_normalized
      write_attribute(:hash_type, 'MD5') if self.simple_hash_value_normalized.length == 32
      write_attribute(:hash_type, 'SHA1') if self.simple_hash_value_normalized.length == 40
      write_attribute(:hash_type, 'SHA224') if self.simple_hash_value_normalized.length == 56
      write_attribute(:hash_type, 'SHA256') if self.simple_hash_value_normalized.length == 64
    end
  end

  def validate_hashes
    if self.hash_type=='MD5' and !simple_hash_value.blank? and !valid_md5(simple_hash_value)
      errors.add(:md5, "MD5 not valid: `#{simple_hash_value}`")
    end
    if self.hash_type=='SHA1' and !simple_hash_value.blank? and !valid_sha1(simple_hash_value)
      errors.add(:sha1, "SHA1 not valid: `#{simple_hash_value}`")
    end
    if self.hash_type=='SHA256' and !simple_hash_value.blank? and !valid_sha256(simple_hash_value)
      errors.add(:sha256, "SHA256 not valid: `#{simple_hash_value}`")
    end
  end

  def valid_md5(hash)
    return false unless hash.length == 32
    return false unless /[0-9a-fA-F]{32}/.match(hash)
    return true
  end

  def valid_sha1(hash)
    return false unless hash.length == 40
    return false unless /[0-9a-fA-F]{40}/.match(hash)
    return true
  end

  def valid_sha256(hash)
    return false unless hash.length == 64
    return false unless /[A-Fa-f0-9]{64}/.match(hash)
    return true
  end
end
