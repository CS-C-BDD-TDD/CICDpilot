class Observable < ActiveRecord::Base
  include Guidable
  include Cyboxable
  include Ingestible
  include Transferable

  VALID_OBSERVABLES = {
      anonymization: ['Address','DnsQuery','DnsRecord','Domain','Hostname','Link','NetworkConnection','Port','SocketAddress','Uri'],
      c2: ['Address','DnsQuery','DnsRecord','Domain','Hostname','HttpSession','Link','NetworkConnection','Port','SocketAddress','Uri'],
      compromised: ['Address','DnsQuery','DnsRecord','Domain','Hostname','Link','NetworkConnection','Port','SocketAddress','Uri'],
      domain_watchlist: ['DnsQuery','DnsRecord','Domain','Hostname','NetworkConnection','Port','SocketAddress'],
      exfiltration: ['Address','DnsQuery','DnsRecord','Domain','Hostname','EmailMessage','CyboxFile','HttpSession','Link','NetworkConnection','Port','SocketAddress','Uri'],
      file_hash_watchlist: ['CyboxFile'],
      host_characteristics: ['Address','DnsQuery','DnsRecord','Domain','Hostname','EmailMessage','CyboxFile','HttpSession','Link','CyboxMutex','SocketAddress','Port','Registry','Uri'],
      ip_watchlist: ['Address','NetworkConnection','Port','SocketAddress'],
      malicious_email: ['EmailMessage'],
      malware_artifacts: ['Address','DnsQuery','DnsRecord','Domain','Hostname','EmailMessage','CyboxFile','HttpSession','Link','CyboxMutex','NetworkConnection','Port','SocketAddress','Registry','Uri'],
      url_watchlist: ['DnsQuery','DnsRecord','Domain','Hostname','Link','NetworkConnection','Port','SocketAddress','Uri'],
      benign: []
  }

  self.table_name = 'cybox_observables'
  belongs_to :indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id, touch: true
  belongs_to :object, polymorphic: true, primary_key: :cybox_object_id, foreign_key: :remote_object_id, foreign_type: :remote_object_type, touch: true

  belongs_to :dns_record, primary_key: :cybox_object_id, class_name: 'DnsRecord', foreign_key: :remote_object_id, touch: true
  belongs_to :dns_query, primary_key: :cybox_object_id, class_name: 'DnsQuery', foreign_key: :remote_object_id, touch: true
  belongs_to :domain, primary_key: :cybox_object_id, class_name: 'Domain', foreign_key: :remote_object_id, touch: true
  belongs_to :hostname, primary_key: :cybox_object_id, class_name: 'Hostname', foreign_key: :remote_object_id, touch: true
  belongs_to :email_message, primary_key: :cybox_object_id, class_name: 'EmailMessage', foreign_key: :remote_object_id, touch: true
  belongs_to :file, primary_key: :cybox_object_id, class_name: 'CyboxFile', foreign_key: :remote_object_id, touch: true
  belongs_to :http_session, primary_key: :cybox_object_id, class_name: 'HttpSession', foreign_key: :remote_object_id, touch: true
  belongs_to :address, primary_key: :cybox_object_id, class_name: 'Address', foreign_key: :remote_object_id, touch: true
  belongs_to :link, primary_key: :cybox_object_id, class_name: 'Link', foreign_key: :remote_object_id, touch: true
  belongs_to :mutex, primary_key: :cybox_object_id, class_name: 'CyboxMutex', foreign_key: :remote_object_id, touch: true
  belongs_to :network_connection, primary_key: :cybox_object_id, class_name: 'NetworkConnection', foreign_key: :remote_object_id, touch: true
  belongs_to :registry, primary_key: :cybox_object_id, class_name: 'Registry', foreign_key: :remote_object_id, touch: true
  belongs_to :socket_address, primary_key: :cybox_object_id, class_name: 'SocketAddress', foreign_key: :remote_object_id, touch: true
  belongs_to :uri, primary_key: :cybox_object_id, class_name: 'Uri', foreign_key: :remote_object_id, touch: true
  belongs_to :port, primary_key: :cybox_object_id, class_name: 'Port', foreign_key: :remote_object_id, touch: true
  validate :has_contained_object?

  after_save :audit_save
  after_destroy :audit_destroy
  
  after_save :set_observable_value_on_indicator
  after_commit :set_observable_value_on_indicator

  object_types = %w{dns_record
                    domain
                    hostname
                    email_message
                    file
                    http_session
                    address
                    link
                    mutex
                    network_connection
                    port
                    registry
                    socket_address
                    dns_query
                    uri}.map &:to_sym

  object_types.each do |type|
    accepts_nested_attributes_for type
  end

  CYBOX_OBJECTS = object_types.collect {|s| s.to_s.pluralize.to_sym}

  before_validation do
    if self.cybox_object_id.present?
      regex=Regexp.new '^'+Setting.STIX_PREFIX+':(.+?-)?'

      if self.cybox_object_id=~regex
        self.is_imported = false
      else
        self.is_imported = true
      end
    else
      self.is_imported = false
    end
    true # This must return true.  This line is here to make sure any new false assignments don't cause a problem
  end

  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["dns_record","dns_query","domain","hostname","email_message","file","http_session","address","link","mutex","network_connection","registry","socket_address","uri","port"]
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
    x = Observable.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Observable of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      if !obj.cybox_object_id.nil?
        x = Observable.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      end
    end
    x.destroy if x.present?
    x = Observable.new

    HumanReview.adjust(obj, uploader)
    x.composite_operator = obj.composite_operator
    if (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)) && !obj.cybox_object_id.nil?
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.is_composite = obj.is_composite
    x.is_negated = obj.is_negated
    x.stix_indicator_id = parent.stix_id unless parent.nil?
    if obj.cybox_objects.present?
       sobj = obj.cybox_objects.first
       x.remote_object_type = sobj.class.to_s.gsub('Stix::Native::Cybox', '')
       x.remote_object_type = 'CyboxFile' if x.remote_object_type == 'File'
       x.remote_object_type = 'CyboxMutex' if x.remote_object_type == 'Mutex'
       x.remote_object_type = 'Registry' if x.remote_object_type == 'WinRegistryKey'
       x.remote_object_type = 'Uri' if x.remote_object_type == 'URI'
       if (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)) && !sobj.cybox_object_id.nil?
        x.remote_object_id = sobj.cybox_object_id + Setting.READ_ONLY_EXT
       else
        x.remote_object_id = sobj.cybox_object_id
       end
    end
    x.read_only = uploader.read_only
    x
  end

  def audit_save
    if (self.object.present? &&
        self.indicator.present? &&
        self.changes.include?("stix_indicator_id") &&
        self.changes.include?("cybox_object_id"))
      audit = Audit.basic
      # Sometimes display names get too big. So lets make sure it doesn't.  Oracle doesnt like messages more than 255 chars.
      obj_dis_name = self.object.display_name
      ind_dis_name = self.indicator.title

      if obj_dis_name.present? && obj_dis_name.length > 100
        obj_dis_name = obj_dis_name[0...100] + "..."
      end

      if ind_dis_name.present? && ind_dis_name.length > 75
        ind_dis_name = ind_dis_name[0...75] + "..."
      end

      audit.message = "#{self.object.class.model_name.human} '#{obj_dis_name}' attached to #{self.indicator.class.model_name.human} '#{ind_dis_name}'"
      audit.audit_type = :link
      ind_audit = audit.dup
      ind_audit.item = self.indicator
      self.indicator.audits << ind_audit
      obs_audit = audit.dup
      obs_audit.item = self.object
      self.object.audits << obs_audit
      return
    end
  end

  def audit_destroy
    if (self.object.present? &&
        self.indicator.present?)
      audit = Audit.basic
      # Sometimes display names get too big. So lets make sure it doesn't.  Oracle doesnt like messages more than 255 chars.
      obj_dis_name = self.object.display_name
      ind_dis_name = self.indicator.title

      if obj_dis_name.length > 100
        obj_dis_name = obj_dis_name[0...100] + "..."
      end

      if ind_dis_name.length > 75
        ind_dis_name = ind_dis_name[0...75] + "..."
      end

      audit.message = "#{self.object.class.model_name.human} #{obj_dis_name} removed from #{self.indicator.class.model_name.human} #{ind_dis_name}"
      audit.audit_type = :unlink
      ind_audit = audit.dup
      ind_audit.item = self.indicator
      self.indicator.audits << ind_audit
      obs_audit = audit.dup
      obs_audit.item = self.object
      self.object.audits << obs_audit
      return
    end
  end

  def object_level_marking
    return unless Setting.CLASSIFICATION
    return if @is_upload
    # this is needed because we create observables for links/url when linking to emails
    return if (self.remote_object_type == "Uri" || self.remote_object_type == "Link") && self.indicator.blank?

    indicator = self.indicator || Indicator.find_by_stix_id(self.stix_indicator_id)
    return if indicator.blank?
    return if self.object.blank? && self.remote_object_type.blank?

    object = self.object || self.remote_object_type.constantize.find_by_cybox_object_id(self.remote_object_id)

    indicator_class = indicator.portion_marking
    object_class = object.portion_marking

    if Classification::CLASSIFICATIONS.index(object_class) > Classification::CLASSIFICATIONS.index(indicator_class)
      errors.add(:base,"Cannot add classified cybox object to indicator of lower classification level")
    end
  end
  
  # Returns the official confidence with the latest date
  # or nil if there are no official confidences
  def latest_confidence
    max_conf = nil
    
    unless object.nil? or object.indicators.nil?
      object.indicators.each {|ind|
        if ind.official_confidence.present? and 
           (max_conf.nil? or ind.official_confidence.stix_timestamp > max_conf.stix_timestamp)
          max_conf = ind.official_confidence
        end
      }
    end
    
    return max_conf
  end
  
  # Returns the total number of sightings recorded
  def total_sightings
    num_sights = 0
    
    unless object.nil? or !object.respond_to?(:total_sightings)
      num_sights = object.total_sightings
    end
    
    return num_sights
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    string :remote_object_type
    string :stix_indicator_id
    text :guid, as: :text_exact
  end

  private

  def set_observable_value_on_indicator
    return unless self.indicator.present?
    self.indicator.set_observable_value
  end

  def has_contained_object?
    if (self.remote_object_id.blank? && self.remote_object_type.blank?) &&
        self.composite_operator.blank?
      errors.add(:observable ," is empty. An observable must contain an object, such as domain or IPv4")
    end
  end
end
