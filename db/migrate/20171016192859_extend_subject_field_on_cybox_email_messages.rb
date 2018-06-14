class ExtendSubjectFieldOnCyboxEmailMessages < ActiveRecord::Migration
  class MCyboxEmailMessage < ActiveRecord::Base
    self.table_name = 'cybox_email_messages'
  end

  def up
    if ActiveRecord::Base.connection.column_exists?(:cybox_email_messages, :msubject)
      remove_column :cybox_email_messages, :msubject
      add_column :cybox_email_messages, :msubject, :string, :limit => 4000
    else
      add_column :cybox_email_messages, :msubject, :string, :limit => 4000
    end

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    total_groups = MCyboxEmailMessage.where('subject is not null').count / 1000
    MCyboxEmailMessage.where('subject is not null').find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch+1} of #{total_groups+1}"
      group.each do |ei|
        ei.msubject = ei.subject
        begin
          ei.save!
        rescue Exception => e
          puts "Could not transition #{ei.id}, skipping subject. Error: #{e.to_s}"
          ei.msubject = ""
          ei.save
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session

    remove_column :cybox_email_messages, :subject
    rename_column :cybox_email_messages, :msubject, :subject
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:cybox_email_messages, :msubject)
      remove_column :cybox_email_messages, :msubject
      add_column :cybox_email_messages, :msubject, :string
    else
      add_column :cybox_email_messages, :msubject, :string
    end

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    total_groups = MCyboxEmailMessage.where('subject is not null').count / 1000
    MCyboxEmailMessage.where('subject is not null').find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch+1} of #{total_groups+1}"
      group.each do |ei|
        ei.msubject = ei.subject
        begin
          ei.save!
        rescue Exception => e
          puts "Could not fully transition #{ei.id}, truncating subject. Error: #{e.to_s}"
          begin
            ei.msubject = ei.subject[0..254]
            ei.save!
          rescue Exception => e
            puts "Could not transition #{ei.id}, skipping subject. Error: #{e.to_s}"
            ei.msubject = ""
            ei.save
          end
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session

    remove_column :cybox_email_messages, :subject
    rename_column :cybox_email_messages, :msubject, :subject
  end
end
