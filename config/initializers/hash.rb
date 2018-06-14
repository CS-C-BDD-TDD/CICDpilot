class Hash
  def hmap(&block)
    self.inject({}){ |hash,(k,v)| hash.merge( block.call(k,v) ) }
  end
end

