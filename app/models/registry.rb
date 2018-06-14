class Registry < ActiveRecord::Base
  self.table_name = "cybox_win_registry_keys"

  module Naming
    def display_name
      value = ''
      if self.hive.present?
        value = "#{value} Hash: #{hive}"
      end
      if self.key.present?
        value = "#{value} Key: #{key}"
      end
      return value
    end
  end

  include Auditable
  include Registry::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Serialized
  include Transferable

  has_many :observables, -> { where remote_object_type: 'Registry' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions
  
  has_many :parameter_observables, -> { where remote_object_type: 'Registry' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables
  
  has_many :registry_values, primary_key: :cybox_object_id, foreign_key: :cybox_object_id

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  CLASSIFICATION_CONTAINER_OF = [:registry_values]

  validates_presence_of :hive
  validates_presence_of :key

  accepts_nested_attributes_for :registry_values, :reject_if => :is_registry_value_empty?, allow_destroy: true
  
  after_commit :set_observable_value_on_indicator

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?

    packages
  end
  
  def self.ingest(uploader, obj, parent = nil)
    x = Registry.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Registry of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : Registry.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
    end


    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
      if x.registry_values.present?
        x.registry_values.each{ |rv| rv.stix_markings.destroy_all }
      end
    end

    x ||= Registry.new
    HumanReview.adjust(obj, uploader)
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.key = obj.key
    x.hive = obj.hive
    x.hive_condition = obj.hive_condition
    x.read_only = uploader.read_only

    x     # Return the unsaved data
  end

  def set_cybox_hash
    fields_array = [self.hive,
                    self.key]
    all_fields = String.new
    fields_array.each do |f|
      unless f.nil?
        all_fields += f
      end
    end

    write_attribute(:cybox_hash, CyboxHash.generate(all_fields))
  end

  def repl_params
    {
      :hive => hive,
      :key => key,
      :guid => guid,
      :cybox_object_id => cybox_object_id
    }
  end

  # Special function for saving registries, we need this because with field level markings we want registry value
  # to be a object level marking instead of a field level marking.
  def self.special_create_or_update(reg_obj=nil, *args)
    # first check if we have a name or value
    if args[0][:registry_values_attributes].present? && args[0][:registry_values_attributes][0].present?
      if (args[0][:registry_values_attributes][0][:reg_name].present? && args[0][:registry_values_attributes][0][:reg_value].blank?) || (args[0][:registry_values_attributes][0][:reg_name].blank? && args[0][:registry_values_attributes][0][:reg_value].present?)
        r = Registry.new
        if args[0][:registry_values_attributes][0][:reg_value].blank?
          r.errors.add(:reg_value, "Value can't be blank if Name is filled out.")
        else
          r.errors.add(:reg_name, "Name can't be blank if Value is filled out.")
        end
        
        if args[0][:key].blank?
          r.errors.add(:key, "Key can't be blank")
        end

        return r
      end

      params = []
      params[0] = {}

      # add them into the args array for saving
      params[0][:reg_value_id] = args[0][:registry_values_attributes][0].delete(:reg_value_id)
      params[0][:reg_name] = args[0][:registry_values_attributes][0].delete(:reg_name)
      params[0][:reg_value] = args[0][:registry_values_attributes][0].delete(:reg_value)
      params[0][:data_condition] = args[0][:registry_values_attributes][0].delete(:data_condition)

      # then we can delete the registry_values_attributes array
      args[0].delete(:registry_values_attributes)

      # build the stix markings array that we will need
      params[0][:stix_markings_attributes] = []

      amount = args[0][:stix_markings_attributes].present? ? args[0][:stix_markings_attributes].count : 0
      # and also add in any field level markings associated with registry value
      (0...amount).each do |x|
        registry_name_markings = args[0][:stix_markings_attributes].index {|e| e[:remote_object_field] == "reg_name"}
        unless registry_name_markings.nil?
          params[0][:stix_markings_attributes] << args[0][:stix_markings_attributes].delete(args[0][:stix_markings_attributes][registry_name_markings])
        end

        registry_value_markings = args[0][:stix_markings_attributes].index {|e| e[:remote_object_field] == "reg_value"}
        unless registry_value_markings.nil?
          params[0][:stix_markings_attributes] << args[0][:stix_markings_attributes].delete(args[0][:stix_markings_attributes][registry_value_markings])
        end
      end

      # the array for registry values
      args[0][:registry_values] = []

      # get the registry object level marking index.
      reg_obj_markings = args[0][:stix_markings_attributes].present? ? args[0][:stix_markings_attributes].index {|e| e[:remote_object_field] == nil} : nil

      # get the obj level marking classification so we can change the registry value hidden object level marking if needed
      unless reg_obj_markings.nil?
        reg_obj_cs_class = args[0][:stix_markings_attributes][reg_obj_markings][:isa_assertion_structure_attributes][:cs_classification]
      end

      # now we should be good to go for saving the registry_values stuff
      if params[0][:reg_value_id] != nil
        # this means registry value already exists and were doing an update
        args[0][:registry_values] << RegistryValue.find_by_id(params[0][:reg_value_id])
        # delete out the reg_value_id because we dont need it anymore
        params[0].delete(:reg_value_id)

        # Always make sure the registry value object level marking is the same as the registry obj level marking
        unless reg_obj_markings.nil?
          markings = args[0][:registry_values][0].stix_markings.where(:remote_object_field => nil).first
          if markings.present? && markings.isa_assertion_structure.present?
            markings.isa_assertion_structure.update_column(:cs_classification, reg_obj_cs_class)
          end
        end

        # we should be good to update at this point
        args[0][:registry_values][0].update(params[0])

        # if their are errors just return the registry_value obj and the controller will return the errors.
        if args[0][:registry_values][0].errors.present?
          return args[0][:registry_values][0]
        end

        # portion markings cache are set after save? need to reload to see it
        args[0][:registry_values][0].reload
      else
        # this means we need to create since registry value doesnt exist
        # so we need to clone the registry object level markings
        unless reg_obj_markings.nil?
          # if we clone over an existing obj_marking it will have id's we need to delete these out
          obj_markings = args[0][:stix_markings_attributes][reg_obj_markings].dup
          obj_markings.delete(:id)
          obj_markings.delete(:controlled_structure)
          obj_markings[:isa_assertion_structure_attributes].delete(:id)
          obj_markings[:isa_assertion_structure_attributes][:isa_privs_attributes].each do |e|
            e.delete(:id)
          end
          obj_markings[:isa_assertion_structure_attributes][:further_sharings_attributes].each do |e|
            e.delete(:id)
          end
          obj_markings[:isa_marking_structure_attributes].delete(:id)

          params[0][:stix_markings_attributes] << obj_markings
        end

        # delete out the reg_value_id because it doesnt exist
        params[0].delete(:reg_value_id)
        # then try and create
        args[0][:registry_values] << RegistryValue.create(params[0])

        # if their are errors just return the registry_value obj and the controller will return the errors.
        if args[0][:registry_values][0].errors.present?
          return args[0][:registry_values][0]
        end

        # portion markings cache are set after save? need to reload to see it
        args[0][:registry_values][0].reload
      end
    end

    if args[0][:cybox_object_id].present? || reg_obj.present?
      registry = reg_obj || Registry.find_by_cybox_object_id(args[0][:cybox_object_id])
    end

    if registry
      registry.update(args[0])
    else
      registry = Registry.create(args[0])
    end

    registry
  end

  def set_controlled_structures
    if self.stix_markings.present?
      self.stix_markings.each { |sm| set_controlled_structure(sm) }
    end
    set_value_controlled_structures
  end

  def set_controlled_structure(sm)
    if sm.present?
      sm.controlled_structure =
          "//cybox:Object[@id='#{self.cybox_object_id}']/"
      if sm.remote_object_field.present?
        case sm.remote_object_field
          when 'hive'
            sm.controlled_structure +=
                'cybox:Properties/WinRegistryKeyObj:Hive/'
          when 'key'
            sm.controlled_structure +=
                'cybox:Properties/WinRegistryKeyObj:Key/'
          else
            sm.controlled_structure = nil
            return
        end
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
  end


  def set_value_controlled_structures
    if self.registry_values.present?
      self.registry_values.each { |rv|
        if rv.stix_markings.present?
          rv.stix_markings.each { |sm|
            rv.set_controlled_structure(sm, self.cybox_object_id)
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

  def is_registry_value_empty?(value)
    if value.empty? || (value['reg_name'].empty? && value['reg_value'].empty?)
      return true
    end
    return false
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :hive
    string :hive
    text :hive_condition
    string :hive_condition
    text :key, as: :text_regkey
    string :key
    time :created_at, stored: false
    time :updated_at, stored: false
    text :cybox_object_id, as: :text_exact
    text :guid, as: :text_exactm
    string :cybox_object_id
    string :portion_marking, stored: false

  end
end
