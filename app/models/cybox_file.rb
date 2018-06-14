class CyboxFile < ActiveRecord::Base
  self.table_name = "cybox_files"

  module Naming
    def display_name
      # Return file_name if present.
      return self.file_name if self.file_name.present?
      # Get the display name from the hash if there is no file_name.
      value = self.get_display_name_from_hash
      # If a hash exists to be used for the display name, return it or else
      # return the cybox_object_id
      value.present? ? value : self.cybox_object_id
    end

		def display_class_name
			"File"
		end
  end

  has_one :gfi, -> { where remote_object_type: 'CyboxFile' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, :dependent => :destroy, :autosave => true
  
  include Auditable
  include CyboxFile::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include Serialized
  include Gfiable
  include AcsDefault
  include Transferable

  has_many :observables, -> { where remote_object_type: 'CyboxFile' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions

  has_many :parameter_observables, -> { where remote_object_type: 'CyboxFile' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  has_many :email_files, primary_key: :guid
  has_many :email_messages, through: :email_files

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  has_many :file_hashes, primary_key: :cybox_object_id, foreign_key: :cybox_file_id
  accepts_nested_attributes_for :file_hashes, :reject_if => :is_hash_value_empty?, allow_destroy: true

  CLASSIFICATION_CONTAINER_OF = [:file_hashes]

  before_save :clear_name_condition

  validate :file_name_or_md5

  after_commit :set_observable_value_on_indicator

  

  def stix_packages
    packages = []

    packages |= self.email_messages.collect(&:stix_packages).flatten if self.email_messages.present?
    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?

    packages
  end
  
  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["file_hashes"]
      associations.each do |a|
        object = self.send a
        if object.present? && self.feeds.present?
          object.each do |x| 
            x.update_column(:feeds, self.feeds) 
            x.try(:trickledown_feed)
          end 
        end
      end
    rescue Exception => e
      ex_msg = "Exception during trickledown_feed on: " + self.class.name    
      ExceptionLogger.debug("#{ex_msg}" + ". #{e.to_s}")
    end
  end    
  
  def self.ingest(uploader, obj, parent = nil)
    x = CyboxFile.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "File of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : CyboxFile.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
      if x.file_hashes.present?
        x.file_hashes.each{ |hash| hash.stix_markings.destroy_all }
      end
      x.file_hashes = []
    end

    x ||= CyboxFile.new
    HumanReview.adjust(obj, uploader)
    #x.apply_condition = obj.apply_condition    # Not in ERD/DB
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    #x.file_extension    # Needs to be calculated if class doesn't do it
    x.file_name = obj.file_name
    x.file_name_condition = obj.file_name_condition
    x.file_path = obj.file_path
    x.file_path_condition = obj.file_path_condition
    x.size_in_bytes = obj.size_in_bytes
    x.size_in_bytes_condition = obj.size_in_bytes_condition
    x.read_only = uploader.read_only
    x
  end

  def md5
    self.file_hashes.each do |hsh|
      return hsh.simple_hash_value_normalized if hsh.hash_type == "MD5"
    end
    return ""
  end

  def set_cybox_hash
    value = ''
    if self.file_name.present?
      value = self.file_name

      if (self.file_name_condition == 'StartsWith')
        value = '^' + value
      elsif (self.file_name_condition == 'EndsWith')
        value += '$'
      end
    elsif self.md5.present?
      value = self.md5
    end
    value = self.display_name if value.blank?

    write_attribute(:cybox_hash, CyboxHash.generate(value))
  end

  # Special create/update needed for objects that are nested inside the create/update of other objects.
  def self.special_markings_create_or_update(cybox_file=nil, *args)
    # Create an empty array of file hashes to store the saved hashes
    args[0][:file_hashes] = []

    # Get the object level classification to check against hashes.
    if args[0][:stix_markings_attributes].present?
      obj_level_class = args[0][:stix_markings_attributes].select {|e| e[:remote_object_field] == nil}[0][:isa_assertion_structure_attributes][:cs_classification]
    else
      obj_level_class = "U"
    end

    # Start saving the hashes with stix_markings as object level markings
    args[0][:file_hashes_attributes].each do |h|
      hash = nil
      if h[:_destroy].blank? || h[:_destroy] == "0"
        
        if h[:id] != nil
          hash = FileHash.find_by_id(h[:id])
        end
        # If you ever decide to want to link up hashes to files uniquely you will need this.
        #else
        #  hash = FileHash.where(h).first
        #  # see if it exists as a normalized value if not add the value back in
        #  if hash.nil? && h[:hash_type] == "SSDEEP"
        #    # save the value first
        #    fuzzy_hash = h[:fuzzy_hash_value]
        #
        #    # then normalize it
        #    h[:fuzzy_hash_value_normalized] = h[:fuzzy_hash_value].downcase
        #    h.delete(:fuzzy_hash_value)
        #    hash = FileHash.where(h).first
        #    if hash.nil?
        #      h[:fuzzy_hash_value] = fuzzy_hash
        #      h.delete(:fuzzy_hash_value_normalized)
        #    end
        #  end
        #end
        ab = h

        # flag to let us know if we set custom markings
        custom_markings = false

        # See if markings were set for the hash
        hash_markings = args[0][:stix_markings_attributes].select {|e| e[:remote_object_field] == h[:hash_type].downcase}

        if hash_markings.present?

          ab[:stix_markings_attributes] = hash_markings

          # get the index of the markings so we can delete it from the set
          hash_markings_index = args[0][:stix_markings_attributes].index {|e| e[:remote_object_field] == h[:hash_type].downcase}
          args[0][:stix_markings_attributes].delete(args[0][:stix_markings_attributes][hash_markings_index])

          # delete out the remote object field because we want to mimic it as object level
          ab[:stix_markings_attributes][0].delete(:remote_object_field)

          # Set the custom markings flag to true so we can update the markings
          custom_markings = true
        else
          ab[:stix_markings_attributes] = []
          # we could have ID's from the existing object level markings so we dont want a copy by ref
          args[0][:stix_markings_attributes].select {|e| e[:remote_object_field] == nil}.each do |t|
            ab[:stix_markings_attributes] << t.deep_dup
          end
          # since we didnt copy by ref we can now delete the id's out.
          if ab[:stix_markings_attributes].present? && !ab[:stix_markings_attributes].blank?
            ab[:stix_markings_attributes].each do |m|
              if m[:id].present?
                # we need to delete out all identifiers so we can clone it as a obj marking
                # First get rid of the controlled strcture
                m.delete(:controlled_structure)
                # then get rid of the remote object type
                m.delete(:remote_object_type)
                # Then start with the top level id's
                m.delete(:id)
                # Then move onto the isa assertion structure
                m[:isa_assertion_structure_attributes].delete(:id)
                m[:isa_assertion_structure_attributes][:isa_privs_attributes].each do |ipa|
                  ipa.delete(:id)
                end
                m[:isa_assertion_structure_attributes][:isa_privs_attributes].each do |fsa|
                  fsa.delete(:id)
                end
                # Next is the isa marking structure
                m[:isa_marking_structure_attributes].delete(:id)
                m[:isa_marking_structure_attributes].delete(:data_item_created_at)
                # now we should be good for saving this as a obj level marking
              end
            end
          end
        end

        if Classification::CLASSIFICATIONS.index(obj_level_class) < Classification::CLASSIFICATIONS.index(ab[:stix_markings_attributes][0][:isa_assertion_structure_attributes][:cs_classification])
          f = CyboxFile.new
          f.errors.add(:base, "Field Level Classifications cannot be higher than the object")
          return f
        end

        if hash.present?
          if custom_markings || hash.stix_markings.blank?
            if custom_markings
              hash.stix_markings.destroy_all
              ab[:stix_markings_attributes][0] = Marking.remote_ids_from_args(ab[:stix_markings_attributes][0])
            end
            hash.update(ab)
          end
        else
          hash = FileHash.create(ab)
        end
        
        args[0][:file_hashes] << hash
      end
    end if args[0][:file_hashes_attributes].present?

    # we have created or updated the file hashes and can now delete the attributes
    args[0].delete(:file_hashes_attributes)

    if args[0][:cybox_object_id].present? || cybox_file.present?
      file = cybox_file || CyboxFile.find_by_cybox_object_id(args[0][:cybox_object_id])
    end

    if file
      file.update(args[0])
    else 
      file = CyboxFile.create(args[0])
    end

    file
  end

  # Get the display name from one of the file hashes by order of precedence
  # for display name and in the proper format.
  def get_display_name_from_hash
    value=''
    type=''
    self.file_hashes.each do |hsh|
      case hsh.hash_type
        when 'MD5'
          # If an MD5 sum exists, return the normalized value immediately
          # since it is highest in precedence.
          return hsh.simple_hash_value_normalized unless
              hsh.simple_hash_value_normalized.empty?
        when 'SHA1'
          # A SHA1 hash is second in precedence so store the display name
          # representation of the hash and set the type.
          unless hsh.simple_hash_value_normalized.empty?
            value = "#{hsh.simple_hash_value_normalized.slice(0, 15)}..."
            type = hsh.hash_type
          end
        when 'SHA256'
          # A SHA256 hash has the lowest precedence so store the display name
          # representation of the hash and set the type only if a SHA1 hash
          # has not already been found to exist.
          unless hsh.simple_hash_value_normalized.empty? || type == 'SHA1'
            value = "#{hsh.simple_hash_value_normalized.slice(0, 15)}..."
            type = hsh.hash_type
          end
      end
    end
    value
  end


  def set_controlled_structures
    if self.stix_markings.present?
      self.stix_markings.each { |sm| set_controlled_structure(sm) }
    end
    set_hash_controlled_structures
  end

  def set_controlled_structure(sm)
    if sm.present?
      sm.controlled_structure =
          "//cybox:Object[@id='#{self.cybox_object_id}']/"
      if sm.remote_object_field.present?
        case sm.remote_object_field
          when 'file_name'
            sm.controlled_structure +=
                'cybox:Properties/FileObj:File_Name/'
          when 'file_path'
            sm.controlled_structure +=
                'cybox:Properties/FileObj:File_Path/'
          when 'size_in_bytes'
            sm.controlled_structure +=
                'cybox:Properties/FileObj:Size_In_Bytes/'
          else
            sm.controlled_structure = nil
            return
        end
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
  end

  def set_hash_controlled_structures
    if self.file_hashes.present?
      self.file_hashes.each { |fh|
        if fh.stix_markings.present?
          fh.stix_markings.each { |sm|
            fh.set_controlled_structure(sm, self.cybox_object_id)
          }
        end
      }
    end
  end

  def total_sightings
    cnt = 0
    cnt = indicators.collect{|ind| ind.sightings.size}.sum
    return cnt
  end

private

  def set_observable_value_on_indicator
    self.indicators.each do |indicator|
      indicator.set_observable_value
    end
  end

  def is_hash_value_empty?(hash)
    return true unless hash.present?
    if (hash['hash_type']=='MD5' or hash['hash_type']=='SHA1' or hash['hash_type']=='SHA256')
      if !hash.keys.include?('simple_hash_value') || hash['simple_hash_value'].empty?
        return true
      end
    elsif hash['hash_type']=='SSDEEP'
      if !hash.keys.include?('fuzzy_hash_value') || hash['fuzzy_hash_value'].empty?
        return true
      end
    end
    return false
  end

  def clear_name_condition
    if self.file_name.blank?
      self.file_name_condition=""
    end
  end

  def file_name_or_md5
    if self.file_name.blank? && self.md5.blank?
      errors.add(:file_name," can't be blank if no MD5 Hash present")
      errors.add(:md5," can't be blank if no File Name present")
    end
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :file_name
    string :file_name
    text :file_name_condition
    string :file_name_condition
    text :hashes do
      file_hashes.map(&:simple_hash_value_normalized)
    end
    text :hash_ids, as: :hash_ids_text_exactm do
      file_hashes.map(&:cybox_object_id)
    end
    time :created_at, stored: false
    time :updated_at, stored: false
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    string :portion_marking, stored: false

    text :guid, as: :text_exactm
  end

  def repl_params
    {
      :file_name => file_name,
      :file_name_condition => file_name_condition,
      :file_path => file_path,
      :file_path_condition => file_path_condition,
      :size_in_bytes => size_in_bytes,
      :size_in_bytes_condition => size_in_bytes_condition,
      :guid => guid,
      :cybox_object_id => guid
    }

  end
end
