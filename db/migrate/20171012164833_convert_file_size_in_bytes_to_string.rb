class ConvertFileSizeInBytesToString < ActiveRecord::Migration
  class MCyboxFile < ActiveRecord::Base
    self.table_name = 'cybox_files'
  end

  def up
    if ActiveRecord::Base.connection.column_exists?(:cybox_files, :msize_in_bytes)
      remove_column :cybox_files, :msize_in_bytes
      add_column :cybox_files, :msize_in_bytes, :string
    else
      add_column :cybox_files, :msize_in_bytes, :string
    end

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    total_groups = MCyboxFile.where('size_in_bytes is not null').count / 1000
    MCyboxFile.where('size_in_bytes is not null').find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch+1} of #{total_groups+1}"
      group.each do |ei|
        ei.msize_in_bytes = ei.size_in_bytes
        begin
          ei.save!
        rescue Exception => e
          puts "Could not transition #{ei.id}, skipping size_in_bytes. Error: #{e.to_s}"
          ei.msize_in_bytes = ""
          ei.save
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session

    remove_column :cybox_files, :size_in_bytes
    rename_column :cybox_files, :msize_in_bytes, :size_in_bytes
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:cybox_files, :msize_in_bytes)
      remove_column :cybox_files, :msize_in_bytes
      add_column :cybox_files, :msize_in_bytes, :integer
    else
      add_column :cybox_files, :msize_in_bytes, :integer
    end

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    total_groups = MCyboxFile.where('size_in_bytes is not null').count / 1000
    MCyboxFile.where('size_in_bytes is not null').find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch+1} of #{total_groups+1}"
      group.each do |ei|
        ei.msize_in_bytes = ei.size_in_bytes
        begin
          ei.save!
        rescue Exception => e
          puts "Could not transition #{ei.id}, skipping size_in_bytes. Error: #{e.to_s}"
          ei.msize_in_bytes = ""
          ei.save
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session

    remove_column :cybox_files, :size_in_bytes
    rename_column :cybox_files, :msize_in_bytes, :size_in_bytes
  end
end
