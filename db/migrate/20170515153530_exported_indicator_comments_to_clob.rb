class ExportedIndicatorCommentsToClob < ActiveRecord::Migration
  class MExportedIndicator < ActiveRecord::Base
    self.table_name = 'exported_indicators'
  end

  def up
    if ActiveRecord::Base.connection.column_exists?(:exported_indicators, :mcomments)
      remove_column :exported_indicators, :mcomments
      add_column :exported_indicators, :mcomments, :text
    else
      add_column :exported_indicators, :mcomments, :text
    end

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    MExportedIndicator.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |ei|
        next if ei.comments.blank?
        ei.mcomments = ei.comments
        begin
          ei.save!
        rescue Exception => e
          puts "Could not transition #{ei.id}, skipping comments. Error: #{e.to_s}"
          ei.mcomments = ""
          ei.save
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session

    rename_column :exported_indicators, :comments, :comments_normalized
    rename_column :exported_indicators, :mcomments, :comments
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:exported_indicators, :comments_normalized)
      remove_column :exported_indicators, :comments
      rename_column :exported_indicators, :comments_normalized, :comments
    else
      if ActiveRecord::Base.connection.column_exists?(:exported_indicators, :mcomments)
        remove_column :exported_indicators, :mcomments
        add_column :exported_indicators, :mcomments, :string
      else
        add_column :exported_indicators, :mcomments, :string
      end

      ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

      MExportedIndicator.find_in_batches.with_index do |group,batch|
        puts "Processing group ##{batch}"
        group.each do |ei|
          next if ei.comments.blank?
          ei.mcomments = ei.comments
          begin
            ei.save!
          rescue Exception => e
            puts "Could not fully transition #{ei.id}, truncating comments. Error: #{e.to_s}"
            begin
              ei.mcomments = ei.comments.truncate(254)
              ei.save!
            rescue Exception => e
              puts "Could not transition #{ei.id}, skipping comments. Error: #{e.to_s}"
              ei.mcomments = ""
              ei.save
            end
          end
        end
      end

      ::Sunspot.session = ::Sunspot.session.original_session

      remove_column :exported_indicators, :comments
      rename_column :exported_indicators, :mcomments, :comments

    end
  end
end
