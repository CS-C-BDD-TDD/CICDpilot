class Time

  def to_atom
    self.strftime("%Y-%m-%dT%H:%M:%SZ")
  end

  def to_atom_date_only
    self.strftime("%Y-%m-%dZ")
  end

end
