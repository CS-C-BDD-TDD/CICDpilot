# Remove the cache columns for field-level markings for the immutable
# objects: addresses, domains, and uris since we now only support
# object-level markings on these objects.
class RemoveCacheColumnsForImmutables < ActiveRecord::Migration
  def change
    remove_column :cybox_addresses, :address_value_normalized_c
    remove_column :cybox_domains, :name_normalized_c
    remove_column :cybox_uris, :uri_normalized_c
  end
end
