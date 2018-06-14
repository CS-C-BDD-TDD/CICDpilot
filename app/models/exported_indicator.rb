class ExportedIndicator < ActiveRecord::Base
  include Guidable
  include Serialized
  include Transferable
  
  acts_as_paranoid(column: 'detasked_at',column_type: 'time')

  EXPORTABLE_SYSTEMS = ['e3a','e2','ecs']

  belongs_to :indicator, primary_key: :guid
  has_many :observables, through: :indicator
  has_many :addresses, through: :observables
  has_many :dns_records, through: :observables
  has_many :dns_queries, through: :observables
  has_many :network_connections, through: :observables
  belongs_to :user

  before_create :set_cached_values
  before_create :assign_current_user
  before_create :add_export_history_to_object
  before_save :retask

  validate :valid_system
  validate :valid_color
  validates_presence_of :system
  validates_presence_of :color
  validate :unique_system_and_indicator, on: :create

  default_scope {order(exported_at: :desc)}

  def delete
		add_delete_history_to_object
	  self.class.delete(id) unless new_record?
	  @destroyed = true
	  freeze
  end

  def system=(system)
    write_attribute(:system,system.to_s.downcase)
  end

  def color=(color)
    write_attribute(:color,color.to_s.downcase)
  end

  def set_to_active
		if self.status == "add" || self.status == "modify"
		  if self.indicator.present?
			  audit = Audit.basic
			  audit.message = "Indicator #{self.indicator.title.presence || self.indicator.stix_id} now Active in #{self.system.upcase}"
			  audit.audit_type = :export
			  audit.audit_subtype = :active
			  audit.item = self.indicator
			  self.indicator.audits << audit
		  end
		  self.status = :active
		  self.update_column(:status, :active)
		end
	end

	def set_cached_values(indicator=nil)
		indicator ||= self.indicator
		self.user = User.current_user
		write_attribute(:username, User.current_user.username) if User.current_user.present?
		write_attribute(:user_id, User.current_user.id) if User.current_user.present?
		write_attribute(:indicator_title, indicator.title)
		write_attribute(:indicator_type, indicator.indicator_type)
		write_attribute(:indicator_stix_id, indicator.stix_id)
		write_attribute(:indicator_classification, indicator.portion_marking)
		write_attribute(:indicator_type_classification, indicator.indicator_type_c)
		write_attribute(:reference,indicator.reference)
    write_attribute(:comments,indicator.description)
    write_attribute(:comments_normalized, indicator.description[0..251] + "...") if indicator.description.present?
		write_attribute(:date_added, indicator.created_at)

		threat_actor = indicator.threat_actors.first

		if threat_actor.present?
			write_attribute(:nai,threat_actor.title)
			write_attribute(:nai_classification,threat_actor.portion_marking)
		end

		observable = indicator.observables.first
		object = observable.object if observable.present?
		object ||= ''

		if object.present?
			write_attribute(:observable_value, indicator.observable_value[0..254]) if indicator.observable_value.present?
			write_attribute(:event_classification, object.portion_marking)

			gfi = object.respond_to?(:gfi) ? object.gfi : nil

			if gfi.present?
				write_attribute(:sid2, gfi.gfi_bluesmoke_id)
				write_attribute(:sid, gfi.gfi_uscert_sid)
			end

			if object.is_a? Domain
				write_attribute(:event,object.name_normalized)
			elsif object.is_a? EmailMessage
				write_attribute(:ps_regex,gfi.gfi_ps_regex) if gfi.present?
				write_attribute(:clear_text, object.from_normalized)
				write_attribute(:signature_location, object.raw_header)
			end
		end

		if threat_actor.present? && object.present?
			nai_translate = Classification.display_name(threat_actor.portion_marking).upcase
			object_translate = Classification.display_name(object.portion_marking).upcase
			nai_share = threat_actor.portion_marking == 'U' ? '' : 'NOT '
			object_share = threat_actor.portion_marking == 'U' ? '' : 'NOT '
			special_instructions = "NAMED AREA OF INTEREST IS #{nai_translate} AND MAY #{nai_share}BE SHARED, EVENT CRITERIA IS #{object_translate} AND MAY #{object_share}BE SHARED."
			write_attribute(:special_instructions,special_instructions)
		end

		write_attribute(:exported_at, DateTime.now)
	end

  private

  def assign_current_user
    self.user ||= User.current_user || User.new(username:'system')
  end

  def valid_system
    unless EXPORTABLE_SYSTEMS.include?(self.system)
      errors.add(:system,"Invalid system to export indicator")
    end
  end

  def valid_color
    if self.indicator.stix_markings.present?
      marking = indicator.stix_markings.joins(:tlp_marking_structure)
      if marking.present?
        available_colors = TlpStructure::COLORS.slice(TlpStructure::COLORS.index(marking.first.tlp_marking_structure.color),TlpStructure::COLORS.size)
        unless available_colors.include?(color)
          errors.add(:color,'Invalid TLP Color, valid colors for this indicator are ' + available_colors.join(', '))
          return
        end
      end
    end

    unless TlpStructure::COLORS.include?(color)
      errors.add(:color,'Invalid TLP Color, valid colors are ' + TlpStructure::COLORS.join(', '))
    end
  end

  def unique_system_and_indicator
    errors.add(:indicator, "This indicator has already been marked for export to this system") if ExportedIndicator.exists?(
        indicator_id: self.indicator_id, system: self.system)
  end

  def add_export_history_to_object
		self.status = :add
    if self.indicator.present?
      audit = Audit.basic
      audit.message = "Indicator #{self.indicator.title.presence || self.indicator.stix_id} Exported to #{self.system.upcase}"
      audit.audit_type = :export
      audit.audit_subtype = :add
      audit.item = self.indicator
      self.indicator.audits << audit
    end
  end

  def retask
		return unless self.changes.include?(:detasked_at) && self.changes[:detasked_at][1].blank?
	  self.status = :add
	  if self.indicator.present?
		  audit = Audit.basic
		  audit.message = "Indicator #{self.indicator.title.presence || self.indicator.stix_id} Retasked to #{self.system.upcase}"
		  audit.audit_type = :export
		  audit.audit_subtype = :add
		  audit.item = self.indicator
		  self.indicator.audits << audit
	  end
  end

  def add_delete_history_to_object
		self.status = :detask
		self.update_column(:status, :detask)
    if self.indicator.present?
      audit = Audit.basic
      audit.message = "Indicator #{self.indicator.title.presence || self.indicator.stix_id} Detasked from #{self.system.upcase}"
      audit.audit_type = :export
      audit.audit_subtype = :detask
      audit.item = self.indicator
      self.indicator.audits << audit
    end
  end

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :indicator_title
    string :indicator_title
    text :observable_value
    text :sid2
    text :comments
    time :date_added, stored: false
    time :exported_at, stored: false
    time :detasked_at, stored: false
    text :event, as: :text_domain
    text :nai
    text :sid
    text :reference
    text :clear_text, as: :text_uax
    text :signature_location
    text :guid, as: :text_exact
    string :indicator_type, stored: false
    string :username, stored: false
    string :indicator_id
    string :system
    string :comments_normalized

    text :addresses, as: :addresses_text_ipm do
      addresses.map(&:address)
    end

    text :dns_records_address, as: :dns_records_address_text_ipm do
      dns_records.map(&:address)
    end

    text :network_connection_source_socket_address, as: :network_connection_source_socket_address_text_ipm do
      network_connections.map(&:source_socket_address)
    end

    text :network_connection_dest_socket_address, as: :network_connection_dest_socket_address_text_ipm do
      network_connections.map(&:dest_socket_address)
    end

    text :dns_query_addresses, as: :dns_query_address_text_ipm do
      dns_queries.map {|dns_query| dns_query.resource_records.map {|rr| rr.dns_records.map(&:address)}}.flatten
    end

    string :indicator_type do
      indicator.indicator_type
    end

    string :remote_object_type, :multiple => true do
      indicator.observables.map do |e|
        e.remote_object_type
      end
    end

  end
end
