class Logging::SystemLog < ActiveRecord::Base
  include Auditable
  attr_accessor :guid
  belongs_to :stix_package, class_name: 'StixPackage', primary_key: :stix_id, foreign_key: :stix_package_id

  belongs_to :ais_statistic, primary_key: :stix_package_stix_id, foreign_key: :sanitized_package_id
  
  validates_presence_of :stix_package_id, :timestamp, :source, :log_level, :message

  before_save :parse_date

  def parse_date
    if self.timestamp.class.to_s=='String'
      self.timestamp = DateTime.parse(self.timestamp)
    end
  end

  def stix_package_id=(value)
    c1 = CiapIdMapping.where(before_id: value).first
    if c1
      write_attribute(:stix_package_id,value)
      write_attribute(:sanitized_package_id,c1.after_id)
    else
      c2 = CiapIdMapping.where(after_id: value).first
      if c2
        write_attribute(:stix_package_id,c2.before_id)
        write_attribute(:sanitized_package_id,value)
      else
        write_attribute(:stix_package_id,value)
      end
    end
  end

  def self.validate_system_logs(system_logs, force_reload=true)
    system_logs_with_errors = []
    if system_logs.present?
      system_logs.each { |system_log|
        begin
          if system_log.valid?
            system_log.reload if force_reload
          else
            system_logs_with_errors << {obj: system_log,
                                        errors: system_log.errors}
          end
        rescue Exception => e
          system_logs_with_errors << {obj: system_log,
                                      errors: e.message.to_s}
        end
      }
    end
    system_logs_with_errors
  end
end
