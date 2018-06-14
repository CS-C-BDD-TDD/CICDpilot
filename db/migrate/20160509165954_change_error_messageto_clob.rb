class ChangeErrorMessagetoClob < ActiveRecord::Migration
  class MErrorMessage < ActiveRecord::Base;self.table_name = :error_messages; end

  def up
    add_column :error_messages,:mdescription,:text

    ErrorMessage.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |message|
        next unless message.mdescription.blank?
        message.mdescription = message.description
        message.save
      end
    end

    remove_column :error_messages,:description
    rename_column :error_messages,:mdescription,:description
  end

  def down
    add_column :error_messages,:mdescription,:string

    ErrorMessage.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |message|
        next unless message.mdescription.blank?
        message.mdescription = message.description
        begin
          message.save!
        rescue Exception => e
          puts "Could not transition #{message.id}, dropping description"
          message.mdescription = ""
          message.save
        end
      end
    end

    remove_column :error_messages,:description
    rename_column :error_messages,:mdescription,:description
  end
end
