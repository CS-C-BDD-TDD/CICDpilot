class AddCacheColumnsToExports < ActiveRecord::Migration
	class MExportedIndicator < ActiveRecord::Base
		self.table_name = :exported_indicators

		belongs_to :indicator, primary_key: :guid
		belongs_to :user, primary_key: :guid
	end

	class MIndicator < ActiveRecord::Base
		has_many :observables, ->{reorder(created_at: :asc)}, primary_key: :stix_id, foreign_key: :stix_indicator_id, dependent: :destroy
		has_many :domains, through: :observables
		has_many :email_messages, through: :observables

		has_many :indicators_threat_actors, primary_key: :stix_id, foreign_key: :stix_indicator_id, dependent: :destroy
		has_many :threat_actors, through: :indicators_threat_actors
	end

	class MDomain < ActiveRecord::Base
		has_many :observables, -> { where remote_object_type: 'Domain' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
		has_many :indicators, through: :observables
		belongs_to :gfi
	end

	class MEmailMessage < ActiveRecord::Base
		has_many :observables, -> { where remote_object_type: 'Email Message' }, primary_key: :cybox_object_id, foreign_key: :remote_object_id
		has_many :indicators, through: :observables
		belongs_to :gfi
	end

	class MObservable < ActiveRecord::Base
		belongs_to :domain, primary_key: :cybox_object_id, class_name: 'Domain', foreign_key: :remote_object_id, touch: true
		belongs_to :email_message, primary_key: :cybox_object_id, class_name: 'EmailMessage', foreign_key: :remote_object_id, touch: true
		belongs_to :indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id, touch: true
		belongs_to :object, polymorphic: true, primary_key: :cybox_object_id, foreign_key: :remote_object_id, foreign_type: :remote_object_type, touch: true
	end

	def up
		add_column :exported_indicators, :sid2, :string
		add_column :exported_indicators, :comments, :string
		add_column :exported_indicators, :date_added, :datetime
		add_column :exported_indicators, :event, :string
		add_column :exported_indicators, :event_classification, :string
		add_column :exported_indicators, :nai, :string
		add_column :exported_indicators, :nai_classification, :string
		add_column :exported_indicators, :special_instructions, :string
		add_column :exported_indicators, :sid, :string
		add_column :exported_indicators, :reference, :string
		add_column :exported_indicators, :cs_regex, :string
		add_column :exported_indicators, :clear_text, :string
		add_column :exported_indicators, :signature_location, :string
		add_column :exported_indicators, :ps_regex, :string
		add_column :exported_indicators, :observable_value, :string
		add_column :exported_indicators, :indicator_title, :string
		add_column :exported_indicators, :indicator_stix_id, :string
		add_column :exported_indicators, :indicator_type, :string
		add_column :exported_indicators, :indicator_classification, :string
		add_column :exported_indicators, :indicator_type_classification, :string
		add_column :exported_indicators, :username, :string

		MExportedIndicator.all.includes(:user,indicator: [:threat_actors,{observables: [:object]},{domains: :gfi},{email_messages: :gfi}]).find_in_batches(batch_size: 1000) do |group|
			group.each do |exp|
				indicator = exp.indicator
				exp.comments = indicator.description
				exp.date_added = indicator.created_at
				exp.indicator_stix_id = indicator.stix_id
				exp.reference = indicator.reference
				exp.indicator_title = indicator.title
				exp.indicator_type = indicator.indicator_type
				exp.indicator_type_classification = indicator.indicator_type_c
				exp.indicator_classification = indicator.portion_marking

				if exp.user.present?
					exp.username = exp.user.username
					exp.user_id = exp.user.id
				end

				threat_actor = indicator.threat_actors.first
				if threat_actor.present?
					exp.nai = threat_actor.title
					exp.nai_classification = threat_actor.portion_marking
				end

				obs = indicator.observables.first
				object = obs.object if obs.present?
				object ||= ''
				exp.observable_value = object.display_class_name + ': ' + object.display_name if object.present?

				domain = indicator.domains.first
				email_message = indicator.email_messages.first

				if domain.present?
					gfi = domain.gfi

					if gfi.present?
						exp.sid2 = gfi.gfi_bluesmoke_id
						exp.sid = gfi.gfi_uscert_sid
					end

					exp.event = domain.name_normalized
					exp.event_classification = domain.portion_marking
				elsif email_message.present?
					gfi = email_message.gfi

					if gfi.present?
						exp.sid2 = gfi.gfi_bluesmoke_id
						exp.sid = gfi.gfi_uscert_sid
						exp.ps_regex = gfi.gfi_ps_regex
					end


					exp.clear_text = email_message.from_normalized
					exp.signature_location = email_message.raw_header
					exp.event_classification = email_message.portion_marking
				else
					exp.event_classification = object.portion_marking if object.present?
				end

				exp.save
			end
		end
	end

	def down
		remove_column :exported_indicators, :sid2
		remove_column :exported_indicators, :comments
		remove_column :exported_indicators, :date_added
		remove_column :exported_indicators, :event
		remove_column :exported_indicators, :event_classification
		remove_column :exported_indicators, :nai
		remove_column :exported_indicators, :nai_classification
		remove_column :exported_indicators, :special_instructions
		remove_column :exported_indicators, :sid
		remove_column :exported_indicators, :reference
		remove_column :exported_indicators, :cs_regex
		remove_column :exported_indicators, :clear_text
		remove_column :exported_indicators, :signature_location
		remove_column :exported_indicators, :ps_regex
		remove_column :exported_indicators, :observable_value
		remove_column :exported_indicators, :indicator_title
		remove_column :exported_indicators, :indicator_type
		remove_column :exported_indicators, :indicator_stix_id
		remove_column :exported_indicators, :indicator_classification
		remove_column :exported_indicators, :indicator_type_classification
		remove_column :exported_indicators, :username
	end
end
