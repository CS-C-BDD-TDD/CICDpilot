module Logging
  class DisseminatedFeed < ActiveRecord::Base
    include Auditable
    attr_accessor :guid

    self.table_name = "disseminated_feeds"

    belongs_to :disseminate
  end
end
