class RemoveCacheColumnsForMutexAndNonStixIndicatorFields < ActiveRecord::Migration
  def change
  	remove_column :cybox_mutexes,:name_c,:string
  end
end
