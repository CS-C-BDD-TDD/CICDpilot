class CreateCyboxObservables < ActiveRecord::Migration
  def change
    create_table :cybox_observables do |t|
      t.string :composite_operator
      t.string :cybox_object_id        # The unique ID of the observable itself
      t.boolean :is_composite, :default => false
      t.boolean :is_imported, :default => false
      t.boolean :is_negated, :default => false
      t.integer :parent_id             # Parent of a Child in a composite
      t.string :remote_object_id       # Unique ID of the CYBOX object
      t.string :remote_object_type     # The type of CYBOX object referenced
      t.string :stix_indicator_id      # The unique ID of an indicator
      t.string :user_guid
      t.timestamps
    end

    add_index :cybox_observables, :cybox_object_id
    add_index :cybox_observables, :parent_id
    add_index :cybox_observables, :remote_object_id
    add_index :cybox_observables, :stix_indicator_id
  end
end
