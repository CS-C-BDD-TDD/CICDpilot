class HttpSession < ActiveRecord::Base

  module Naming
    def display_name
      return get_name
    end

    def display_class_name
	    "HTTP Session"
    end
  end
  
  def get_name
    value = ''
    if self.user_agent.present?
      value = self.user_agent
    end
    if self.domain_name.present?
      value += ' ' + self.domain_name
      if self.port.present?
        value += ':' + self.port
      end
    end
    if self.user_agent.nil? && self.domain_name.nil?
      value = self.cybox_object_id
    end
    value
  end

  self.table_name = "cybox_http_sessions"

  include Auditable
  include HttpSession::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include AcsDefault
  include Serialized
  include Transferable
  
  after_save :update_linked_indicators

  has_many :observables, -> { where remote_object_type: 'HttpSession' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions

  has_many :parameter_observables, -> { where remote_object_type: 'HttpSession' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  has_many :layer_seven_connections, class_name: 'LayerSevenConnection', primary_key: :cybox_object_id, foreign_key: :http_session_id
  
  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  validates_presence_of :user_agent
  after_commit :set_observable_value_on_indicator

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?
    packages |= self.layer_seven_connections.collect(&:stix_packages).flatten if self.layer_seven_connections.present?

    packages
  end

  def self.ingest(uploader, obj, parent = nil)
    x = HttpSession.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "HTTP Session of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : HttpSession.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= HttpSession.new
    HumanReview.adjust(obj, uploader)
    x.user_agent = obj.user_agent
    x.user_agent_condition = obj.user_agent_condition
    x.domain_name = obj.domain_name
    x.port = obj.port
    x.referer = obj.referer
    x.pragma = obj.pragma
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.read_only = uploader.read_only
    x
  end

  def set_cybox_hash
    write_attribute(:cybox_hash, CyboxHash.generate(get_name))
  end

  def repl_params
    {
      :user_agent => user_agent,
      :domain_name => domain_name,
      :port => port,
      :referer => referer,
      :pragma => pragma,
      :cybox_object_id => cybox_object_id,
      :guid => guid
    }
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
      field_xpath_segment = 'cybox:Properties/' +
              'HTTPSessionObj:HTTP_Request_Response/' +
              'HTTPSessionObj:HTTP_Client_Request/' +
              'HTTPSessionObj:HTTP_Request_Header/' +
              'HTTPSessionObj:Parsed_Header/'
      if sm.remote_object_field.present?
        case sm.remote_object_field
          when 'user_agent'
            sm.controlled_structure += field_xpath_segment +
                'HTTPSessionObj:User_Agent/'
          when 'domain_name'
            sm.controlled_structure += field_xpath_segment +
                'HTTPSessionObj:Host/HTTPSessionObj:Domain_Name/'
          when 'port'
            sm.controlled_structure += field_xpath_segment +
                'HTTPSessionObj:Host/HTTPSessionObj:Port/'
          when 'referer'
            sm.controlled_structure += field_xpath_segment +
                'HTTPSessionObj:Referer/'
          when 'pragma'
            sm.controlled_structure += field_xpath_segment +
                'HTTPSessionObj:Pragma/'
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

  def set_observable_value_on_indicator
    self.indicators.each do |indicator|
      indicator.set_observable_value
    end
  end

  def update_linked_indicators
    unless self.changes.empty?
      self.indicators.each do |i|
        audit = Audit.basic
        audit.message = "HTTP Session observable updated"
        audit.details = self.changes.except("updated_at")
        audit.item = i
        audit.audit_type = :observable_update
        i.audits << audit
        i.updated_at = Time.now
        i.save
      end
    end
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :user_agent
    string :user_agent
    text :user_agent_condition
    string :user_agent_condition
    text :domain_name
    string :domain_name
    text :pragma
    string :pragma
    text :port
    string :port
    text :referer, as: :text_uaxm
    string :referer
    time :created_at, stored: false
    time :updated_at, stored: false
    text :cybox_object_id, as: :text_exact
    text :guid, as: :text_exactm
    string :cybox_object_id
    string :portion_marking, stored: false

  end
end
