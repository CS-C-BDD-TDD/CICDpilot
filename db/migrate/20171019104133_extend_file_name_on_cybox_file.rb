class ExtendFileNameOnCyboxFile < ActiveRecord::Migration
  class MCyboxFile < ActiveRecord::Base
    self.table_name = 'cybox_files'
  end

  def up
    if ActiveRecord::Base.connection.column_exists?(:cybox_files, :mfile_name)
      remove_column :cybox_files, :mfile_name
      add_column :cybox_files, :mfile_name, :string, :limit => 4000
    else
      add_column :cybox_files, :mfile_name, :string, :limit => 4000
    end

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    total_groups = MCyboxFile.where('file_name is not null').count / 1000
    MCyboxFile.where('file_name is not null').find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch+1} of #{total_groups+1}"
      group.each do |ei|
        ei.mfile_name = ei.file_name
        begin
          ei.save!
        rescue Exception => e
          puts "Could not transition #{ei.id}, skipping file_name. Error: #{e.to_s}"
          ei.mfile_name = ""
          ei.save
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session

    remove_column :cybox_files, :file_name
    rename_column :cybox_files, :mfile_name, :file_name
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:cybox_files, :mfile_name)
      remove_column :cybox_files, :mfile_name
      add_column :cybox_files, :mfile_name, :string
    else
      add_column :cybox_files, :mfile_name, :string
    end

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    total_groups = MCyboxFile.where('file_name is not null').count / 1000
    MCyboxFile.where('file_name is not null').find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch+1} of #{total_groups+1}"
      group.each do |ei|
        ei.mfile_name = ei.file_name
        begin
          ei.save!
        rescue Exception => e
          puts "Could not fully transition #{ei.id}, truncating file_name. Error: #{e.to_s}"
          begin
            ei.mfile_name= ei.file_name[0..254]
            ei.save!
          rescue Exception => e
            puts "Could not transition #{ei.id}, skipping file_name. Error: #{e.to_s}"
            ei.mfile_name = ""
            ei.save
          end
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session

    remove_column :cybox_files, :file_name
    rename_column :cybox_files, :mfile_name, :file_name
  end
end
