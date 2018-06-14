class Public::FileSerializer < Serializer
  attributes :file_name,
             :file_extension,
             :file_name_condition,
             :file_path,
             :file_path_condition,
             :size_in_bytes,
             :size_in_bytes_condition,
             :cybox_hash,
             :cybox_object_id
end