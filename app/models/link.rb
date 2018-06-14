class Link < ActiveRecord::Base
  self.table_name = "cybox_links"

  include Auditable
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Serialized
  include Transferable
  
  belongs_to :uri, primary_key: :cybox_object_id, foreign_key: :uri_object_id
  has_many :email_links, primary_key: :guid
  has_many :email_messages, through: :email_links
  has_many :observables, -> { where remote_object_type: 'Link' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions
  
  has_many :parameter_observables, -> { where remote_object_type: 'Link' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  CLASSIFICATION_CONTAINER_OF = [:uri]
  CLASSIFICATION_CONTAINED_BY = [:email_links, :email_messages, :indicators, :ind_course_of_actions,
                                 :parameter_observables, :course_of_actions]

  before_save :set_cybox_hash

  validates_presence_of :label
  validates_presence_of :uri
  validates_uniqueness_of :label, :scope => :uri_object_id, unless: :duplication_needed?
  accepts_nested_attributes_for :uri

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?
    packages |= self.email_messages.collect(&:stix_packages).flatten if self.email_messages.present?

    packages
  end
    
  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["uri"]
      associations.each do |a|       
        object = self.send a
        if object.present? && self.feeds.present?
          object.update_column(:feeds, self.feeds) 
          object.try(:trickledown_feed)
        end
      end
    rescue Exception => e
      ex_msg = "Exception during trickledown_feed on: " + self.class.name    
      ExceptionLogger.debug("#{ex_msg}" + ". #{e.to_s}")
    end
  end   

  def self.ingest(uploader, obj, parent = nil)
    x = Link.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Link of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : Link.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= Link.new
    HumanReview.adjust(obj, uploader)
    x.label = obj.url_label
    x.label_condition = obj.url_label_condition
    x.uri_attributes = {:uri_raw => obj.uri.name_raw, :uri_condition => obj.uri.uri_condition}
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.read_only = uploader.read_only
    x
  end

  def duplication_needed?
    cybox_object_id && cybox_object_id.include?(Setting.READ_ONLY_EXT)
  end

  def display_name
    return "Uri: #{uri.uri_input}, Label: #{label}"
  end

  # Overriding find_or_create_by because it does not handle accept_nested_attributes_for, so instead, I'm sending in the
  # :uri_input value by itself, and having this override method handle the lookup/create of the Uri object, and then
  # attach it to the args so the Link find_or_create_by can use it to find or create the proper Link object
  def self.find_or_create_by(*args)
    # In order to perform the find_or_create_by on both Link and Uri, we send in the :uri_input value and override find_or_create_by
    # Here, we do a find_or_create_by on Uri, looking up or creating by the uri_input value, and we place it into the args array
    # Here, we do a find on Uri, looking up by the uri_input value, and create it if necessary, placing it into the args array
    label = args[0][:label]
    if args[0][:uri_attributes]
      uri_input = args[0][:uri_attributes][:uri_input]
      uri_condition = args[0][:uri_attributes][:uri_condition]
    else
      uri_input = nil
      uri_condition = "Equals"
    end
    args[0].delete(:label)
    args[0].delete(:uri_attributes)

    # if we have a field level marking for Labels we need to delete it out here for now.
    label_markings_index = args[0][:stix_markings_attributes].present? ? args[0][:stix_markings_attributes].index {|e| e[:remote_object_field] == 'label'} : nil
    unless label_markings_index.nil?
      label_markings = args[0][:stix_markings_attributes].delete(args[0][:stix_markings_attributes][label_markings_index])
    end

    # see if we have uri_markings so we can potentially update/save them, 
    uri_markings_index = args[0][:stix_markings_attributes].present? ? args[0][:stix_markings_attributes].index {|e| e[:remote_object_field] == 'uri_normalized'} : nil
    unless uri_markings_index.nil?
      # this is actually object level marking so set remote object field to nil
      args[0][:stix_markings_attributes][uri_markings_index][:remote_object_field] = nil
    end

    if uri_input.present?
      # See if we can find a uri by the uri normalized
      args[0][:uri]=Uri.find_by_uri_normalized_sha256(Digest::SHA256.hexdigest(uri_input.downcase))

      # if uri exists that means we need to do an update for the stix markings
      if args[0][:uri].present?
        # check if field level markings exist for uri_normalized in uri that means we need to update the object level for uri
        unless uri_markings_index.nil?
          # we need to update object markings inside the uri object
          params = []
          params[0] = {}
          params[0][:stix_markings_attributes] = []
          params[0][:stix_markings_attributes] << args[0][:stix_markings_attributes][uri_markings_index]

          # just update the markings
          args[0][:uri].stix_markings.select{|s| s.remote_object_field.nil?}.first.update(params[0][:stix_markings_attributes][0])

          # when we updated the markings portion marking didnt update so we need to do that too, since the callback is on the object not the marking
          args[0][:uri].set_portion_marking

          # return if errors.
          if args[0][:uri].errors.present?
            return args[0][:uri]
          end
        end
      end
    end

    unless args[0][:uri]
      if args[0][:uri].nil?
        args[0].delete(:uri)
      end
      # create a object for params for the uri
      params = []
      params[0] = {}
      params[0][:stix_markings_attributes] = []
      if args[0][:stix_markings_attributes].present?
        if uri_markings_index.nil?
          params[0][:stix_markings_attributes] << args[0][:stix_markings_attributes][0]
        else
          params[0][:stix_markings_attributes] << args[0][:stix_markings_attributes][uri_markings_index]
        end
      end
      params[0][:uri_input] = uri_input
      params[0][:uri_condition] = uri_condition

      args[0][:uri]=Uri.create(params[0])

      if args[0][:uri].errors.present?
        return args[0][:uri]
      end
    end

    # delete out the uri field level markings if they exist because we already saved them
    unless uri_markings_index.nil?
      args[0][:stix_markings_attributes].delete(args[0][:stix_markings_attributes][uri_markings_index])
    end

    # stick the label field level markings back in if they exist
    unless label_markings.blank?
      args[0][:stix_markings_attributes] << label_markings
    end

    # add the label back in to the args[0] so we can save the link
    args[0][:label] = label

    link = Link.create(args[0])

    link
  end

  # Since we need to have a different path for updates because of classification rules messing us up we need a seperate update method
  def self.find_or_update_by(link_obj=nil, *args)
    # In order to perform the find_or_update_by on both Link and Uri, we need to first save the object level markings on the link first so uri can update correctly
    # so we need to delete out all uri information and do the link stuff first
    if args[0][:uri_attributes].present?
      uri_input = args[0][:uri_attributes][:uri_input]
    else
      uri_input = nil
    end
    args[0].delete(:uri_attributes)

    # see if we have uri_markings so we can potentially update/save them, 
    uri_markings_index = args[0][:stix_markings_attributes].index {|e| e[:remote_object_field] == 'uri_normalized'}
    unless uri_markings_index.nil?
      # this is actually object level marking so set remote object field to nil
      args[0][:stix_markings_attributes][uri_markings_index][:remote_object_field] = nil
    end

    # delete out the uri markings if they exist and save them for later
    unless uri_markings_index.blank?
      # first lets do a quick check if uri markings are greater than the object level on link.

      # First get the object level classification
      obj_level_index = args[0][:stix_markings_attributes].index {|e| e[:remote_object_field].nil?}
      if obj_level_index.present?
        obj_level_class = args[0][:stix_markings_attributes][obj_level_index][:isa_assertion_structure_attributes][:cs_classification]
      else
        obj_level_class = "U"
      end

      if Classification::CLASSIFICATIONS.index(obj_level_class) < Classification::CLASSIFICATIONS.index(args[0][:stix_markings_attributes][uri_markings_index][:isa_assertion_structure_attributes][:cs_classification])
        l = Link.new
        l.errors.add(:base, 'URI Classification cannot be higher than the object')
        return l
      end

      uri_markings = args[0][:stix_markings_attributes].delete(args[0][:stix_markings_attributes][uri_markings_index])
    end

    ####### Link saving #######

    # Save the stix markings so we can try and find the existing link object
    stix_markings_attributes = args[0][:stix_markings_attributes]
    args[0].delete(:stix_markings_attributes)

    # Try to find the existing link cybox object if it exists
    link = nil
    if args[0][:cybox_object_id].present? || link_obj.present?
      link = link_obj || Link.find_by_cybox_object_id(args[0][:cybox_object_id])
    end

    # add the stix markings back into the args so we can update now
    args[0][:stix_markings_attributes] = stix_markings_attributes
    if link.present?
      link.update(args[0])
    end

    if link.errors.present?
      return link
    end
    ####### Link saving end #######

    # Clean up section

    # if we have a field level marking for Labels we need to delete it.
    label_markings_index = args[0][:stix_markings_attributes].index {|e| e[:remote_object_field] == 'label'}
    unless label_markings_index.nil?
      args[0][:stix_markings_attributes].delete(args[0][:stix_markings_attributes][label_markings_index])
    end

    ## Uri updating

    if uri_input.present?
      # See if we can find a uri by the uri normalized
      args[0][:uri]=Uri.find_by_uri_normalized_sha256(Digest::SHA256.hexdigest(uri_input.downcase))

      # if uri exists that means we need to do an update for the stix markings
      if args[0][:uri].present?
        # check if field level markings exist for uri_normalized in uri that means we need to update the object level for uri
        unless uri_markings_index.nil?
          # we need to update object markings inside the uri object
          params = []
          params[0] = {}
          params[0][:stix_markings_attributes] = []
          params[0][:stix_markings_attributes] << uri_markings

          args[0][:uri].update(params[0])

          if args[0][:uri].errors.present?
            return args[0][:uri]
          end
        end
      end
    end

    ## Uri updating end
    
    # return the saved link
    link
  end

  def set_cybox_hash
    value = self.label.to_s
    value += self.uri.uri_normalized.to_s if self.uri.present?
    write_attribute(:cybox_hash, CyboxHash.generate(value))
  end

  def set_controlled_structures
    if self.stix_markings.present?
      self.stix_markings.each { |sm| set_controlled_structure(sm) }
    end
  end

  def set_controlled_structure(sm)
    if sm.present?
      sm.controlled_structure =
          "//cybox:Object[@id='#{self.cybox_object_id}']/"
      if sm.remote_object_field.present?
        case sm.remote_object_field
          when 'label'
            sm.controlled_structure +=
                'cybox:Properties/LinkObj:URL_Label/'
          else
            sm.controlled_structure = nil
            return
        end
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
  end

  def total_sightings
    cnt = 0
    cnt = indicators.collect{|ind| ind.sightings.size}.sum
    return cnt
  end

private

  after_commit :set_observable_value_on_indicator
  def set_observable_value_on_indicator
    self.indicators.each do |indicator|
      indicator.set_observable_value
    end
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :label, as: :text_uaxm
    string :label
    text :label_condition
    string :label_condition
    time :created_at, stored: false
    time :updated_at, stored: false
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    string :portion_marking, stored: false
    text :guid, as: :text_exactm

    text :uri, as: :uris_text_uaxm do
      uri.uri if uri
    end

    string :uri do
      uri.uri if uri
    end

    text :uri_condition, as: :text_uaxm do
      uri.uri_condition if uri
    end

    string :uri_condition do
      uri.uri_condition if uri
    end

  end
end
