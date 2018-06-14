# These are the ESSA Information Sharing Architecture (ISA) attributes for
# doing resource markings. The remote_object_id and remote_object_type columns
# are included because the standard requires the identification of the specific
# resource effected, and it seemed better to NOT rely on XPATH within a
# relational database.

class IsaMarkings < ActiveRecord::Migration
  def change
    create_table :isa_markings do |t|
      t.string   :community_dissemination, limit: 2000      # CSV strings
      t.datetime :data_item_created_at                      # When created
      t.string   :dissemination_controls                    # FOU, NF, etc.
      t.string   :guid
      t.string   :org_dissemination                         # DOD, DHS, etc.
      t.boolean  :public_release, null: false, default: false
      t.string   :re_country, limit: 2000                   # Responsible Entity
      t.string   :re_organization                           # Responsible Entity
      t.string   :re_suborganization                        # Responsible Entity
      t.string   :releasable_to                             # Countries
      t.string   :stix_marking_id                           # Foreign Key
      t.string   :user_status_dissemination                 # MIL, GOV, etc.
      t.timestamps
    end

    add_index :isa_markings, :stix_marking_id
  end
end
