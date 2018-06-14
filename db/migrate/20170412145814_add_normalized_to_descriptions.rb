class AddNormalizedToDescriptions < ActiveRecord::Migration
  class MCourseOfAction < ActiveRecord::Base
    self.table_name = :course_of_actions
  end

  class MVulnerability < ActiveRecord::Base
    self.table_name = :vulnerabilities
  end

  def up
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    if !ActiveRecord::Base.connection.column_exists?(:course_of_actions, :description_normalized)
      add_column :course_of_actions, :description_normalized, :string
    end

    if !ActiveRecord::Base.connection.column_exists?(:vulnerabilities, :description_normalized)
      add_column :vulnerabilities, :description_normalized, :string
    end

    MCourseOfAction.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |obj|
        begin
          if obj.description.present?
            obj.description_normalized = obj.description.strip[0..254]
            obj.save!
          end
        rescue Exception => e
          puts "Could not transition Course Of action id: #{obj.id}, Exception: #{e.to_s}"
        end
      end
    end

    MVulnerability.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |obj|
        begin
          if obj.description.present?
            obj.description_normalized = obj.description.strip[0..254]
            obj.save!
          end
        rescue Exception => e
          puts "Could not transition Vulnerabilities id: #{obj.id}, Exception: #{e.to_s}"
        end
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session
  end

  def down
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    # set the old id's back on the tables
    if ActiveRecord::Base.connection.column_exists?(:course_of_actions, :description_normalized)
      remove_column :course_of_actions, :description_normalized, :string
    end

    if ActiveRecord::Base.connection.column_exists?(:vulnerabilities, :description_normalized)
      remove_column :vulnerabilities, :description_normalized, :string
    end

    ::Sunspot.session = ::Sunspot.session.original_session
  end
end
