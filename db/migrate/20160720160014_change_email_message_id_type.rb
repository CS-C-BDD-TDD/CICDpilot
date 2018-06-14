class ChangeEmailMessageIdType < ActiveRecord::Migration
  class MEmailLink < ActiveRecord::Base;self.table_name = :email_links end
  class MEmailUri < ActiveRecord::Base;self.table_name = :email_uris end


  def up
    add_column :email_uris, :temp_message_id, :integer
    add_column :email_links, :temp_message_id, :integer
    add_column :email_links, :temp_link_id, :integer
    add_column :email_uris, :temp_uri_id, :integer

    MEmailUri.reset_column_information
    MEmailLink.reset_column_information

    MEmailUri.all.find_in_batches do |group|
      group.each do |uri|
        uri.temp_message_id = uri.email_message_id.to_i
        uri.temp_uri_id = uri.uri_id.to_i
        begin
          uri.save!
        rescue Exception => e
          raise Exception, "ActiveRecord Exception: #{e.message}, for object #{uri.class.to_s} id # #{uri.id}"
        end
      end
    end

    MEmailLink.all.find_in_batches do |group|
      group.each do |link|
        link.temp_message_id = link.email_message_id.to_i
        link.temp_link_id = link.link_id.to_i
        begin
          link.save!
        rescue Exception => e
          raise Exception, "ActiveRecord Exception: #{e.message}, for object #{link.class.to_s} id # #{link.id}"
        end
      end
    end

    remove_column :email_uris, :email_message_id
    remove_column :email_links, :email_message_id
    remove_column :email_uris, :uri_id
    remove_column :email_links, :link_id

    rename_column :email_uris, :temp_message_id, :email_message_id
    rename_column :email_links, :temp_message_id, :email_message_id
    rename_column :email_uris, :temp_uri_id, :uri_id
    rename_column :email_links, :temp_link_id, :link_id
  end

  def down
    change_column :email_uris, :email_message_id, :string
    change_column :email_links, :email_message_id, :string
    change_column :email_uris, :uri_id, :string
    change_column :email_links, :link_id, :string
  end
end
