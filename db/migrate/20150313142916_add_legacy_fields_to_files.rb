class AddLegacyFieldsToFiles < ActiveRecord::Migration
  def change
    add_column :cybox_files, :legacy_file_type, :text
    add_column :cybox_files, :legacy_registry_edits, :text
    add_column :cybox_files, :legacy_av_signature_mcafee, :string
    add_column :cybox_files, :legacy_av_signature_microsoft, :string
    add_column :cybox_files, :legacy_av_signature_symantec, :string
    add_column :cybox_files, :legacy_av_signature_trendmicro, :string
    add_column :cybox_files, :legacy_av_signature_kaspersky, :string
    add_column :cybox_files, :legacy_compiled_at, :datetime
    add_column :cybox_files, :legacy_compiler_type, :string
    add_column :cybox_files, :legacy_cve, :text
    add_column :cybox_files, :legacy_keywords, :text
    add_column :cybox_files, :legacy_mutex, :text
    add_column :cybox_files, :legacy_packer, :string
    add_column :cybox_files, :legacy_xor_key, :string
    add_column :cybox_files, :legacy_motif_name, :string
    add_column :cybox_files, :legacy_motif_size, :string
    add_column :cybox_files, :legacy_composite_hash, :string
    add_column :cybox_files, :legacy_command_line, :string
  end
end
