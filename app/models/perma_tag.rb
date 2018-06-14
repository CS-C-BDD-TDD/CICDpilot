class PermaTag < SystemTag
  after_initialize -> {self.is_permanent=true}

  def self.default_scope
    where(user_guid: nil).where(is_permanent:true)
  end
end