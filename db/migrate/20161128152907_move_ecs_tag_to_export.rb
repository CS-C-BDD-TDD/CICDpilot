class MoveEcsTagToExport < ActiveRecord::Migration
  class MSystemTag < ActiveRecord::Base
	  self.table_name = 'tags'

		has_many :tag_assignments, foreign_key: :tag_guid, primary_key: :guid, class_name: 'MTagAssignment'
		has_many :indicators, through: :tag_assignments, primary_key: :guid, foreign_key: :remote_object_guid, source: :remote_object, source_type: 'Indicator'
  end

  class MExportedIndicator < ActiveRecord::Base
		self.table_name = :exported_indicators

		belongs_to :indicator, primary_key: :guid
		belongs_to :user, primary_key: :guid
  end

  class MTagAssignment < ActiveRecord::Base
		self.table_name = :tag_assignments

	  belongs_to :user, foreign_key: :user_guid, primary_key: :guid
	  belongs_to :remote_object, polymorphic: true, primary_key: :guid, touch: true, foreign_key: :remote_object_guid
	  belongs_to :system_tag, foreign_key: :tag_guid, primary_key: :guid, class_name: 'MSystemTag'
  end

  class MIndicator < ActiveRecord::Base
		self.table_name = :stix_indicators

		has_many :audits, -> {where(item_type_audited: 'Indicator')}, foreign_key: :item_guid_audited, primary_key: :guid
  end

  class MAudit < ActiveRecord::Base
	  self.table_name = 'audit_logs'

	  belongs_to :item, polymorphic: true, foreign_key: :item_guid_audited, foreign_type: :item_type_audited, primary_key: :guid
	  belongs_to :user, primary_key: :guid, foreign_key: :user_guid
  end


	def up
		ecs_tag = MSystemTag.find_by_name("exported-to-ecs")
		raise ActiveRecord::RecordNotFound, 'System missing Exported To ECS System Tag' if ecs_tag.nil?

		ecs_tag.tag_assignments.where(tag_assignments: {remote_object_type: 'Indicator'}).includes(:user,remote_object: :audits).find_in_batches do |group|
			group.each do |tag_assignment|
				indicator = tag_assignment.remote_object
				user = tag_assignment.user
				exp = MExportedIndicator.new(indicator: indicator,system: 'ecs',user: user, exported_at: tag_assignment.created_at)
				exp.save!

				audits = indicator.audits.where(audit_type: "tag").where(Audit.arel_table[:message].matches("%exported-to-ecs%"))
				audits.each do |audit|
					audit.audit_type = 'export'
					audit.audit_subtype = 'add'
					audit.message = "Indicator #{indicator.title.presence || indicator.stix_id} Exported to #{exp.system.upcase}"
					audit.save!
				end

				tag_assignment.destroy
			end
		end

		ecs_tag.destroy
  end

	def down
		ecs_tag = MSystemTag.create(name: "exported-to-ecs", name_normalized: "exported-to-ecs", guid: SecureRandom.uuid)

		MExportedIndicator.where(system: 'ecs').includes(:user, indicator: :audits).find_in_batches do |group|
			group.each do |exp_ind|
				MTagAssignment.create(remote_object: exp_ind.indicator,system_tag: ecs_tag,user: exp_ind.user, created_at: exp_ind.exported_at)

				audits = exp_ind.indicator.audits.where(audit_type: "export").where(audit_subtype: 'add')
				audits.each do |audit|
					audit.audit_type = 'tag'
					audit.audit_subtype = ''
					audit.message = "Tagged Indicator with 'exported-to-ecs'"
					audit.save!
				end

				exp_ind.destroy
			end
		end
	end
end
