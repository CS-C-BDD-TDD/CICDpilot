class ParameterObservable < ActiveRecord::Base
  include Guidable
  include Cyboxable
  include Ingestible
  include Transferable

  self.table_name = 'parameter_observables'
  belongs_to :course_of_action, primary_key: :stix_id, foreign_key: :stix_course_of_action_id, touch: true
  belongs_to :object, polymorphic: true, primary_key: :cybox_object_id, foreign_key: :remote_object_id, foreign_type: :remote_object_type, touch: true

  belongs_to :address, primary_key: :cybox_object_id, class_name: 'Address', foreign_key: :remote_object_id, touch: true
  belongs_to :dns_query, primary_key: :cybox_object_id, class_name: 'DnsQuery', foreign_key: :remote_object_id, touch: true
  belongs_to :dns_record, primary_key: :cybox_object_id, class_name: 'DnsRecord', foreign_key: :remote_object_id, touch: true
  belongs_to :domain, primary_key: :cybox_object_id, class_name: 'Domain', foreign_key: :remote_object_id, touch: true
  belongs_to :hostname, primary_key: :cybox_object_id, class_name: 'Hostname', foreign_key: :remote_object_id, touch: true
  belongs_to :email_message, primary_key: :cybox_object_id, class_name: 'EmailMessage', foreign_key: :remote_object_id, touch: true
  belongs_to :file, primary_key: :cybox_object_id, class_name: 'CyboxFile', foreign_key: :remote_object_id, touch: true
  belongs_to :http_session, primary_key: :cybox_object_id, class_name: 'HttpSession', foreign_key: :remote_object_id, touch: true
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


  object_types = %w{address
                    dns_record
                    domain
                    hostname
                    email_message
                    file
                    http_session
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

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    string :remote_object_type
    string :stix_course_of_action_id
    text :guid, as: :text_exact
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
    x = ParameterObservable.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Parameter Observable of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      if !obj.cybox_object_id.nil?
        x = ParameterObservable.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      end
    end
    x.destroy if x.present?
    x = ParameterObservable.new

    if (uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)) && !obj.cybox_object_id.nil?
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.stix_course_of_action_id = parent.stix_id unless parent.nil?
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
    if self.changes.include?("stix_course_of_action_id") && self.changes.include?("cybox_object_id")
      audit = Audit.basic
      # Sometimes display names get too big. So lets make sure it doesn't.  Oracle doesnt like messages more than 255 chars.
      obj_dis_name = self.object.present? ? self.object.display_name : self.remote_object_id.to_s
      coa_dis_name = self.course_of_action.present? ? self.course_of_action.title : self.stix_course_of_action_id.to_s

      if obj_dis_name.length > 100
        obj_dis_name = obj_dis_name[0...100] + "..."
      end

      if coa_dis_name.length > 75
        coa_dis_name = coa_dis_name[0...75] + "..."
      end

      audit.message = "#{self.object.class.model_name.human} '#{obj_dis_name}' attached to #{self.course_of_action.class.model_name.human} '#{coa_dis_name}'"
      audit.audit_type = :link

    if self.course_of_action.present?
      ind_audit = audit.dup
      ind_audit.item = self.course_of_action
      self.course_of_action.audits << ind_audit
    end

    if self.object.present?
      obs_audit = audit.dup
      obs_audit.item = self.object
      self.object.audits << obs_audit
    end
    
    return

    end
  end

  def audit_destroy
    if (self.object.present? &&
        self.course_of_action.present?)
      audit = Audit.basic
      # Sometimes display names get too big. So lets make sure it doesn't.  Oracle doesnt like messages more than 255 chars.
      obj_dis_name = self.object.display_name
      coa_dis_name = self.course_of_action.title

      if obj_dis_name.length > 100
        obj_dis_name = obj_dis_name[0...100] + "..."
      end

      if coa_dis_name.length > 75
        coa_dis_name = coa_dis_name[0...75] + "..."
      end

      audit.message = "#{self.object.class.model_name.human} #{obj_dis_name} removed from #{self.course_of_action.class.model_name.human} #{coa_dis_name}"
      audit.audit_type = :unlink
      ind_audit = audit.dup
      ind_audit.item = self.course_of_action
      self.course_of_action.audits << ind_audit
      obs_audit = audit.dup
      obs_audit.item = self.object
      self.object.audits << obs_audit
      return
    end
  end

  def object_level_marking
    return unless Setting.CLASSIFICATION
    return if @is_upload

    course_of_action = self.course_of_action || CourseOfAction.find_by_stix_id(self.stix_course_of_action_id)
    return if course_of_action.blank?
    return if self.object.blank? && self.remote_object_type.blank?

    object = self.object || self.remote_object_type.constantize.find_by_cybox_object_id(self.remote_object_id)

    course_of_action_class = course_of_action.portion_marking
    object_class = object.portion_marking

    if Classification::CLASSIFICATIONS.index(object_class) > Classification::CLASSIFICATIONS.index(course_of_action_class)
      errors.add(:base,"Cannot add classified cybox object to Course Of Action of lower classification level")
    end
  end

  private

  def has_contained_object?
    if self.remote_object_id.blank? && self.remote_object_type.blank?
      errors.add(:observable ," is empty. An observable must contain an object, such as domain or IPv4")
    end
  end
end
