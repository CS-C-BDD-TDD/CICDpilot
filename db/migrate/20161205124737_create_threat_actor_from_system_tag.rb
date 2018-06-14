class CreateThreatActorFromSystemTag < ActiveRecord::Migration
  class MThreatActor < ActiveRecord::Base
    include Auditable
    include Guidable

    self.table_name = :threat_actors

    include AcsDefault

    has_many :stix_markings, primary_key: :guid, as: :remote_object
    has_many :indicators_threat_actors, primary_key: :stix_id, foreign_key: :threat_actor_id
    has_many :indicators, through: :indicators_threat_actors
    belongs_to :created_by_user, class_name: 'User', primary_key: :guid, foreign_key: :created_by_user_guid
    has_many :isa_marking_structures, primary_key: :stix_id, through: :stix_markings
    has_many :isa_assertion_structures, primary_key: :stix_id, through: :stix_markings
  end

  class MIndicatorsThreatActor < ActiveRecord::Base
    self.table_name = :indicators_threat_actors
    belongs_to :indicator, primary_key: :stix_id, foreign_key: :stix_indicator_id, touch: true
    belongs_to :threat_actor, primary_key: :stix_id, foreign_key: :threat_actor_id, class_name: MThreatActor
    belongs_to :user, foreign_key: :user_guid, primary_key: :guid
  end

  class MSystemTag < ActiveRecord::Base
    include Guidable
    self.table_name = :tags

    def self.default_scope
      where user_guid: nil
    end

    has_many :tag_assignments,
             foreign_key: :tag_guid,
             primary_key: :guid

    has_many :indicators,
             through: :tag_assignments,
             primary_key: :guid,
             foreign_key: :remote_object_guid,
             source: :remote_object,
             source_type: 'Indicator'
  end

  class MTagAssignment < ActiveRecord::Base
    self.table_name = :tag_assignments

    belongs_to :user,
               foreign_key: :user_guid,
               primary_key: :guid

    belongs_to :remote_object,
               polymorphic: true,
               primary_key: :guid,
               touch: true,
               foreign_key: :remote_object_guid

    belongs_to :system_tag,
               foreign_key: :tag_guid,
               primary_key: :guid, class_name: MSystemTag
  end

  def up
    MSystemTag.where("name LIKE 'FO%'").each do |st|
      next if st.name=='excluded-from-e1' or st.name=='exported-to-ecs'
      t=MThreatActor.new
      t.title=st.name
      t.identity_name=st.name
      t.stix_id="NCCIC:ThreatActor-" + SecureRandom.uuid
      t.save
      MThreatActor.create_default_policy(t)
      st.tag_assignments.find_in_batches.each do |group|
        group.each do |tag_assignment|
          MIndicatorsThreatActor.create!(
              indicator: tag_assignment.remote_object,
              threat_actor: t,
              created_at: tag_assignment.created_at,
              user: tag_assignment.user
          ) if tag_assignment.remote_object_type == 'Indicator'
        end
      end

      st.destroy
    end

    sys_tag_per = Permission.find_by_name('create_remove_system_tags')

    p1 = Permission.find_or_create_by(name: 'create_remove_threat_actors')
    if p1
      p1.name='create_remove_threat_actors'
      p1.display_name='Create and Remove Threat Actors'
      p1.description='The user can create and remove Threat Actors.'
      if sys_tag_per
        p1.groups = sys_tag_per.groups
      end
      p1.save!
    end

    sys_tag_per = Permission.find_by_name('tag_item_with_system_tag')

    p2 = Permission.find_or_create_by(name: 'add_indicator_to_threat_actor')
    if p2
      p2.name='add_indicator_to_threat_actor'
      p2.display_name='Add and Remove Indicator to/from Threat Actor'
      p2.description='The user can add an Indicator to and remove an Indicator from a Threat Actor.'

      if sys_tag_per
        p2.groups = sys_tag_per.groups
      end
      p2.save!
    end
  end

  def down
    MThreatActor.all.each do |ta|
      tag = MSystemTag.new
      tag.name = ta.title
      tag.name_normalized = tag.name.downcase
      tag.save
      ta.indicators_threat_actors.find_in_batches.each do |group|
        group.each do |indicators_threat_actor|
          MTagAssignment.create!(
              remote_object: indicators_threat_actor.indicator,
              system_tag: tag,
              created_at: indicators_threat_actor.created_at,
              user: indicators_threat_actor.user
          )
        end
      end
      ta.destroy
    end

    Permission.find_by_name('create_remove_threat_actors').destroy
    Permission.find_by_name('add_indicator_to_threat_actor').destroy
  end
end
