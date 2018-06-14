class AddIsCiscpToObservables < ActiveRecord::Migration
  def change
    add_column :cybox_observables, :is_ciscp, :boolean, :default => false
  end
end
