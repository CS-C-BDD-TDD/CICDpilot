class EmailMessage < ActiveRecord::Base

  module RawAttribute
    module Writers
      def sender_raw=(value, stix_markings = nil)
        if User.has_permission(User.current_user,'view_pii_fields')
          if value.present?
            sender = Address.find_or_create_by({address_value_raw: value}, stix_markings)
            self.sender_address = sender
          else
            write_attribute(:sender_normalized, normalized_value(value))
            write_attribute(:sender_raw, value)
          end
        end
      end

      def reply_to_raw=(value, stix_markings = nil)
        if User.has_permission(User.current_user,'view_pii_fields')
          if value.present?
            reply_to = Address.find_or_create_by({address_value_raw: value}, stix_markings)
            self.reply_to_address = reply_to
          else
            write_attribute(:reply_to_normalized, normalized_value(value))
            write_attribute(:reply_to_raw, value)
          end
        end
      end

      def from_raw=(value, stix_markings = nil)
        if User.has_permission(User.current_user,'view_pii_fields')
          
          if value.present?
            from = Address.find_or_create_by({address_value_raw: value}, stix_markings)
            self.from_address = from
          else
            write_attribute(:from_normalized, normalized_value(value))
            write_attribute(:from_raw, value)
          end
        end
      end

      def x_originating_ip=(value, stix_markings = nil)
        if value.present?
          x_originating_ip = Address.find_or_create_by({address_value_raw: value}, stix_markings)
          self.x_ip_address = x_originating_ip
        else
          write_attribute(:x_originating_ip, normalized_value(value))
        end
      end

      def x_mailer=(value)
        if User.has_permission(User.current_user,'view_pii_fields')
          write_attribute(:x_mailer,value)
        end
      end

      def raw_header=(value)
        if User.has_permission(User.current_user,'view_pii_fields')
          write_attribute(:raw_header,value)
        end
      end

      def raw_body=(value)
        if User.has_permission(User.current_user,'view_pii_fields')
          write_attribute(:raw_body,value)
        end
      end

      def sender_address=(address)
        if address.present? && address.class == Address
          self.link_address_audit(address, "Sender") if address.address_value_raw != self.sender_raw
          write_attribute(:sender_normalized, normalized_value(address.address_value_raw))
          write_attribute(:sender_raw, address.address_value_raw)
          write_attribute(:sender_cybox_object_id, address.cybox_object_id)
          write_attribute(:sender_normalized_c, address.portion_marking)
        end
      end

      def reply_to_address=(address)
        if address.present? && address.class == Address
          self.link_address_audit(address, "Reply-To") if address.address_value_raw != self.reply_to_raw
          write_attribute(:reply_to_normalized, normalized_value(address.address_value_raw))
          write_attribute(:reply_to_raw, address.address_value_raw)
          write_attribute(:reply_to_cybox_object_id, address.cybox_object_id)
          write_attribute(:reply_to_normalized_c, address.portion_marking)
        end
      end

      def from_address=(address)
        if address.present? && address.class == Address
          self.link_address_audit(address, "From Address") if address.address_value_raw != self.from_raw
          write_attribute(:from_normalized, normalized_value(address.address_value_raw))
          write_attribute(:from_raw, address.address_value_raw)
          write_attribute(:from_cybox_object_id, address.cybox_object_id)
          write_attribute(:from_normalized_c, address.portion_marking)
        end
      end

      def x_ip_address=(address)
        if address.present? && address.class == Address
          self.link_address_audit(address, "X Originating IP") if address.address_value_normalized != self.x_originating_ip
          write_attribute(:x_originating_ip, normalized_value(address.address_value_normalized))
          write_attribute(:x_ip_cybox_object_id, address.cybox_object_id)
          write_attribute(:x_originating_ip_c, address.portion_marking)
        end
      end
    end
  end

  module Normalize
    def normalized_value(raw)
      return raw if raw.nil?
      raw.strip.downcase
    end
  end

  module Naming
    def display_name
      # This is shown in the audit trail, so PII must not be shown
      value = ''
      if self.subject.present?
        value = "Subject: #{subject}"
      else
        value = "(No subject)"
      end
      return value
    end

    def display_class_name
	    "E-mail"
    end
  end

  has_one :gfi, -> { where remote_object_type: 'EmailMessage' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, :dependent => :destroy, :autosave => true
  
  self.table_name = "cybox_email_messages"

  include Auditable
  include EmailMessage::RawAttribute::Writers
  include EmailMessage::Normalize
  include EmailMessage::Naming
  include Guidable
  include Cyboxable
  include Ingestible
  include Serialized
  include Gfiable
  include AcsDefault
  include Transferable

  has_many :observables, -> { where remote_object_type: 'EmailMessage' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id, dependent: :destroy
  has_many :indicators, through: :observables
  has_many :ind_course_of_actions, through: :indicators, class_name: 'CourseOfAction', source: :course_of_actions
  
  has_many :parameter_observables, -> { where remote_object_type: 'EmailMessage' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
  has_many :course_of_actions, through: :parameter_observables

  has_many :email_links, primary_key: :guid
  has_many :links, through: :email_links
  has_many :email_uris, primary_key: :guid
  has_many :uris, through: :email_uris
  has_many :email_files, primary_key: :guid
  has_many :cybox_files, through: :email_files

  has_many :badge_statuses, primary_key: :guid, as: :remote_object, dependent: :destroy

  belongs_to :sender_address, class_name: 'Address', primary_key: :cybox_object_id, foreign_key: :sender_cybox_object_id
  belongs_to :reply_to_address, class_name: 'Address', primary_key: :cybox_object_id, foreign_key: :reply_to_cybox_object_id
  belongs_to :from_address, class_name: 'Address', primary_key: :cybox_object_id, foreign_key: :from_cybox_object_id
  belongs_to :x_ip_address, class_name: 'Address', primary_key: :cybox_object_id, foreign_key: :x_ip_cybox_object_id

  alias_attribute :from, :from_normalized
  alias_attribute :from_input, :from_raw
  alias_attribute :reply_to, :reply_to_normalized
  alias_attribute :reply_to_input, :reply_to_raw
  alias_attribute :sender, :sender_normalized
  alias_attribute :sender_input, :sender_raw

  validate :any_required_fields_present?
  validate :email_addresses_valid?
  validate :valid_address

  CLASSIFICATION_CONTAINER_OF = [:links, :uris, :sender_address, :reply_to_address, :from_address, :x_ip_address, :cybox_files]

  #before_save :create_cybox_object_ids
  after_save :update_linked_indicators
  after_commit :set_observable_value_on_indicator

  def stix_packages
    packages = []

    packages |= self.course_of_actions.collect(&:stix_packages).flatten if self.course_of_actions.present?
    packages |= self.indicators.collect(&:stix_packages).flatten if self.indicators.present?

    packages
  end
  
  # Trickles down the disseminated feed value to all of the associated objects
  def trickledown_feed
    begin
      associations = ["sender_address", "reply_to_address", "from_address", "x_ip_address", "links", "cybox_files"]
      associations.each do |a|       
        object = self.send a
        if object.present? && self.feeds.present?
          if object.class.to_s.include?("Collection")
            object.each do |x|
              x.update_column(:feeds, self.feeds)
              x.try(:trickledown_feed)
            end
          else
            object.update_column(:feeds, self.feeds) 
            object.try(:trickledown_feed)
          end
        end
      end
    rescue Exception => e
      ex_msg = "Exception during trickledown_feed on: " + self.class.name    
      ExceptionLogger.debug("#{ex_msg}" + ". #{e.to_s}")
    end
  end 

  def self.ingest(uploader, obj, parent = nil)
    x = EmailMessage.find_by_cybox_object_id(obj.cybox_object_id)
    if x.present? && uploader.overwrite == false && uploader.read_only == false
      IngestUtilities.add_warning(uploader, "Email Message of #{obj.cybox_object_id} already exists.  Skipping.  Select overwrite to add")
      return x
    elsif uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x = obj.cybox_object_id.nil? ? nil : EmailMessage.find_by_cybox_object_id(obj.cybox_object_id + Setting.READ_ONLY_EXT)
      if x.present? 
        x.destroy
        x = nil
      end
    end

    if x.present?
      # Destroy all existing STIX markings to be re-ingested.
      x.stix_markings.destroy_all
    end

    x ||= EmailMessage.new
    HumanReview.adjust(obj, uploader)
    #x.apply_condition = obj.apply_condition
    if uploader.read_only || (Setting.CLASSIFICATION == true && uploader.overwrite)
      x.cybox_object_id = obj.cybox_object_id ? obj.cybox_object_id + Setting.READ_ONLY_EXT : obj.cybox_object_id
    else
      x.cybox_object_id = obj.cybox_object_id  # Reset to incoming CYBOX Obj ID
    end
    x.subject_condition = obj.subject_condition
    x.email_date = obj.email_date
    x.raw_body = obj.raw_body
    x.raw_header = obj.raw_header
    x.subject = obj.subject
    x.message_id = obj.message_id
    x.x_mailer = obj.x_mailer
    # These 3 should be created when the address is set on the fields
    # x.from_cybox_object_id = obj.from_cybox_object_id if obj.respond_to?(:from_cybox_object_id)
    # x.reply_to_cybox_object_id = obj.reply_to_cybox_object_id if obj.respond_to?(:reply_to_cybox_object_id)
    # x.sender_cybox_object_id = obj.sender_cybox_object_id if obj.respond_to?(:sender_cybox_object_id)
    x.read_only = uploader.read_only
    x
  end

  def set_cybox_hash
    fields_array = [self.from_normalized,
                    self.reply_to_normalized,
                    self.sender_normalized,
                    self.subject]
    all_fields = String.new
    fields_array.each do |f|
      unless f.nil?
        all_fields += f
      end
    end

    write_attribute(:cybox_hash, CyboxHash.generate(all_fields))
  end

  # Special function for saving/updates preprocessing because of imbedded objects.
  def self.custom_save_or_update(email_message=nil, *args)
    if args[0][:cybox_object_id].present? || email_message.present?
      email = email_message || EmailMessage.find_by_cybox_object_id(args[0][:cybox_object_id])
    end

    # let us first check if the addresses exist to know if we need to create them.
    address_fields = {
      :sender_input => ["sender_normalized", "sender_cybox_object_id"],
      :reply_to_input => ["reply_to_normalized", "reply_to_cybox_object_id"],
      :from_input => ["from_normalized", "from_cybox_object_id"],
      :x_originating_ip => ["x_originating_ip", "x_ip_cybox_object_id"]
    }

    address_fields.each do |field|
      # if the address is inputted but the address object doesnt exist we need to create it.
      if args[0][field.first].present? && !Address.find_by_address(args[0][field.first].downcase).present?
        # first see if we have custom markings.
        field_markings = args[0][:stix_markings_attributes].index {|x| x[:remote_object_field] == field.second.first} if args[0][:stix_markings_attributes].present?
        # if they exist use them
        begin
          if field_markings.present?
            markings = args[0][:stix_markings_attributes][field_markings]
            markings[:remote_object_field] = nil
            stix_markings = StixMarking.create(markings)
            Address.find_or_create_by({address_value_raw: args[0][field.first].strip.downcase}, stix_markings)
            args[0][:stix_markings_attributes].delete(args[0][:stix_markings_attributes][field_markings])
          # if not we need to clone from the object of the email object.
          else
            field_markings = Marking.remote_ids_from_args(args[0][:stix_markings_attributes].select {|x| x[:remote_object_field] == nil}.first)
            stix_markings = StixMarking.create(field_markings)
            Address.find_or_create_by({address_value_raw: args[0][field.first].strip.downcase}, stix_markings)
          end
        rescue Exception => e
          if stix_markings.present? && stix_markings.remote_object_id.blank?
            stix_markings.destroy
          end
        end
      elsif args[0][field.first].blank?
        args[0][field.second.second] = nil
      end
    end

    if email
      email.update(args[0])
    else 
      email = EmailMessage.create(args[0])
    end

    email
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
          when 'subject'
            sm.controlled_structure +=
                'cybox:Properties/EmailMessageObj:Header/' +
                    'EmailMessageObj:Subject/'
          when 'email_date'
            sm.controlled_structure +=
                'cybox:Properties/EmailMessageObj:Header/' +
                    'EmailMessageObj:Date/'
          when 'raw_body'
            sm.controlled_structure +=
                'cybox:Properties/EmailMessageObj:Raw_Body/'
          when 'raw_header'
            sm.controlled_structure +=
                'cybox:Properties/EmailMessageObj:Raw_Header/'
          when 'message_id'
            sm.controlled_structure +=
                'cybox:Properties/EmailMessageObj:Header/' +
                    'EmailMessageObj:Message_ID/'
          when 'x_mailer'
            sm.controlled_structure +=
                'cybox:Properties/EmailMessageObj:Header/' +
                    'EmailMessageObj:X_Mailer/'
          else
            sm.controlled_structure = nil
            return
        end
      end
      sm.controlled_structure += 'descendant-or-self::node()'
      sm.controlled_structure += "| #{sm.controlled_structure}/@*"
    end
  end

  def link_address_audit(item, field)
    audit = Audit.basic
    audit.message = "Address '#{item.cybox_object_id}' added to Email '#{self.cybox_object_id}' for field '#{field}'"
    audit.audit_type = :email_address_link
    other_audit = audit.dup
    other_audit.item = item
    item.audits << other_audit
    obj_audit = audit.dup
    obj_audit.item = self
    self.audits << obj_audit
  end

  def update_address_portion_markings(portion_marking, col)
    update_attribute(col, portion_marking)
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

  def any_required_fields_present?
    field_list = ['from_normalized','reply_to_normalized','sender_normalized','subject']
    if field_list.all?{|attr| self[attr].blank?}
      errors.add :from_normalized, "You must fill in at least one field"
      errors.add :reply_to_normalized, "You must fill in at least one field"
      errors.add :sender_normalized, "You must fill in at least one field"
      errors.add :subject, "You must fill in at least one field"
    end
  end

  def email_addresses_valid?
    unless valid_email_address?(self.sender)
      errors.add :sender_normalized, "Invalid email address format"
    end

    unless valid_email_address?(self.reply_to)
      errors.add :reply_to_normalized, "Invalid email address format"
    end

    unless valid_email_address?(self.from)
      errors.add :from_normalized, "Invalid email address format"
    end
  end

  def valid_email_address?(raw)
    return true if raw.nil? || raw.blank?
    return false unless /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\z/i.match(raw)
    return true
  end

  def self.valid_ipv4_value?(raw)
    return unless raw.present?
    begin
      IPAddress::IPv4.new(raw.strip)
      true
    rescue ArgumentError
      false
    end
  end

  def valid_ipv6_value?(raw)
    return unless raw.present?
    begin
      IPAddress::IPv6.new(raw.strip)
      true
    rescue ArgumentError
      false
    end
  end
  
  def valid_address
    return unless self.x_originating_ip
    unless Address.valid_ipv4_value?(self.x_originating_ip) || Address.valid_ipv6_value?(self.x_originating_ip)
      errors.add(:x_originating_ip ,"`#{x_originating_ip}` is not valid")
      return
    end
  end

  def repl_params
    {
      :email_date => email_date,
      :message_id => message_id,
      :subject => subject,
      :x_originating_ip => x_originating_ip,
      :guid => guid,
      :cybox_object_id => cybox_object_id
    }

  end

  def update_linked_indicators
    unless self.changes.empty?
      self.indicators.each do |i|
        audit = Audit.basic
        audit.message = "Email observable updated"
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
    text :from_normalized, as: :text_uaxm
    string :from_normalized
    text :reply_to_normalized, as: :text_uaxm
    string :reply_to_normalized
    text :sender_normalized, as: :text_uaxm
    string :sender_normalized
    text :subject
    string :subject
    text :subject_condition
    string :subject_condition
    text :guid, as: :text_exactm
    time :created_at, stored: false
    time :updated_at, stored: false
    text :cybox_object_id, as: :text_exact
    string :cybox_object_id
    string :portion_marking, stored: false

  end
end
