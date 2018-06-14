module Logging
  class Disseminate < ActiveRecord::Base
    include Auditable
    attr_accessor :guid, :disseminated_on

    self.table_name = "disseminated_records"

    has_many :disseminated_feeds

    after_save :save_feeds

    def save_feeds
      unless disseminated_on.empty?
        disseminated_on.each do |o|
          d=Logging::DisseminatedFeed.new
          d.disseminate_id=self.id
          d.feed=o
          d.save
        end
      end
    end
  end
end
