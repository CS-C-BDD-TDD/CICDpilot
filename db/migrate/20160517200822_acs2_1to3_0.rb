class Acs21to30 < ActiveRecord::Migration
  def up
    Rake::Task['acs_migration'].execute
  end

  def down
    puts "Cannot rollback this migration"
  end
end