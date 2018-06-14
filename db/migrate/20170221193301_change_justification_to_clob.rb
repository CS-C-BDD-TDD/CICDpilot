class ChangeJustificationToClob < ActiveRecord::Migration

  class MAudit < ActiveRecord::Base
    self.table_name = 'audit_logs'
  end

  def up
    if ActiveRecord::Base.connection.column_exists?(:audit_logs, :mjustification)
      remove_column :audit_logs, :mjustification
      add_column :audit_logs, :mjustification, :text
    else
      add_column :audit_logs, :mjustification, :text
    end

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    MAudit.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |audit|
        next if audit.justification.blank?
        audit.mjustification = audit.justification
        begin
          audit.save!
        rescue Exception => e
          puts "Could not transition #{audit.id}, skipping justification"
          audit.mjustification = ""
          audit.save
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session

    rename_column :audit_logs, :justification, :old_justification
    rename_column :audit_logs, :mjustification, :justification
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:audit_logs, :old_justification)
      remove_column :audit_logs, :justification
      rename_column :audit_logs, :old_justification, :justification
    else
      if ActiveRecord::Base.connection.column_exists?(:audit_logs, :mjustification)
        remove_column :audit_logs, :mjustification
        add_column :audit_logs, :mjustification, :string
      else
        add_column :audit_logs, :mjustification, :string
      end

      ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

      MAudit.find_in_batches.with_index do |group,batch|
        puts "Processing group ##{batch}"
        group.each do |audit|
          next if audit.justification.blank?
          audit.mjustification = audit.justification
          begin
            audit.save!
          rescue Exception => e
            puts "Could not transition #{audit.id}, truncating justification"
            begin
              audit.mjustification = audit.justification.truncate(245)
              audit.save!
            rescue Exception => e
              puts "Could not transition #{audit.id}, skipping justification"
              audit.mjustification = ""
              audit.save
            end
          end
        end
      end

      ::Sunspot.session = ::Sunspot.session.original_session

      remove_column :audit_logs, :justification
      rename_column :audit_logs, :mjustification, :justification

    end
  end
end
