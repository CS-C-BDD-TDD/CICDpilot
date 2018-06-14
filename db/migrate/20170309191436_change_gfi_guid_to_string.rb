class ChangeGfiGuidToString < ActiveRecord::Migration

  class MGfi < ActiveRecord::Base
    self.table_name = "gfis"
  end

  def up
    if !ActiveRecord::Base.connection.column_exists?(:gfis, :mguid)
      add_column :gfis, :mguid, :string
    end

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    MGfi.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |gfi|
        next if gfi.guid.blank?
        next if gfi.mguid.present?
        gfi.mguid = gfi.guid
        begin
          gfi.save!
        rescue Exception => e
          puts "Could not transition #{gfi.id}, skipping guid"
          gfi.mguid = ""
          gfi.save
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session

    rename_column :gfis, :guid, :old_guid
    rename_column :gfis, :mguid, :guid
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:gfis, :old_guid)
      remove_column :gfis, :guid
      rename_column :gfis, :old_guid, :guid
    else
      if !ActiveRecord::Base.connection.column_exists?(:gfis, :mguid)
        add_column :gfis, :mguid, :text
      end

      ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

      MGfi.find_in_batches.with_index do |group,batch|
        puts "Processing group ##{batch}"
        group.each do |gfi|
          next if gfi.guid.blank?
        	next if gfi.mguid.present?
          gfi.mguid = gfi.guid
          begin
            gfi.save!
          rescue Exception => e
            puts "Could not transition #{gfi.id}, truncating guid"
            begin
              gfi.mguid = gfi.guid.truncate(245)
              gfi.save!
            rescue Exception => e
              puts "Could not transition #{gfi.id}, skipping guid"
              gfi.mguid = ""
              gfi.save
            end
          end
        end
      end

      ::Sunspot.session = ::Sunspot.session.original_session

      remove_column :gfis, :guid
      rename_column :gfis, :mguid, :guid

    end
  end

end
