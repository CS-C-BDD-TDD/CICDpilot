class AddSha2HashToOriginalInput < ActiveRecord::Migration

  class MOriginalInput < ActiveRecord::Base
    self.table_name = :original_input

    def raw_content
      if read_attribute(:raw_content).present?
        return read_attribute(:raw_content).force_encoding("UTF-8")
      end

      ""
    end
  end

  def up
    add_column :original_input, :sha2_hash, :string
    populate_hashes
  end

  def down
    remove_column :original_input, :sha2_hash
  end

  def populate_hashes
    if defined?(Digest)
      MOriginalInput.all.each do |obj|
        d = Digest::SHA2.new << obj.raw_content
        obj.sha2_hash = d.to_s
        obj.save
      end
    else
      raise "ERROR: No Digest class defined! SHA2 hashes not calculated."
    end
  end

end
