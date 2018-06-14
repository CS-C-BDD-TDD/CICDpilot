class ChangeUriToText < ActiveRecord::Migration
  def up
    add_column :cybox_uris, :muri_normalized, :text
    add_column :cybox_uris, :muri_raw, :text
    add_column :cybox_uris, :uri_normalized_sha256, :string

    Uri.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |u|
        u.muri_normalized = u.uri_normalized
        u.muri_raw = u.uri_raw
        u.uri_normalized_sha256 = Digest::SHA256.hexdigest(u.uri_normalized)
        u.save
      end
    end

    remove_column :cybox_uris, :uri_normalized
    rename_column :cybox_uris, :muri_normalized, :uri_normalized
    remove_column :cybox_uris, :uri_raw
    rename_column :cybox_uris, :muri_raw, :uri_raw
  end

  def down
    add_column :cybox_uris, :muri_normalized, :string
    add_column :cybox_uris, :muri_raw, :string

    Uri.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"
      group.each do |u|
        u.muri_normalized = u.uri_normalized
        u.muri_raw = u.uri_raw
        begin
          u.save!
        rescue Exception => e
          puts "Could not transition #{u.id}, dropping uri"
          u.muri_normalized = ""
          u.muri_raw = ""
          u.save
        end
      end
    end

    remove_column :cybox_uris, :uri_normalized
    rename_column :cybox_uris, :muri_normalized, :uri_normalized
    remove_column :cybox_uris, :uri_raw
    rename_column :cybox_uris, :muri_raw, :uri_raw
    remove_column :cybox_uris, :uri_normalized_sha256
  end
end
