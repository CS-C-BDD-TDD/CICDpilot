# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180424145540) do

  create_table "acs_sets", force: :cascade do |t|
    t.string   "name"
    t.string   "stix_id"
    t.string   "guid"
    t.integer  "old_acs_sets_org_id"
    t.string   "color"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "locked",              default: false
    t.string   "portion_marking"
    t.string   "acs_sets_org_id"
    t.boolean  "transfer_from_low",   default: false
  end

  create_table "acs_sets_organizations", force: :cascade do |t|
    t.integer  "old_organization_id"
    t.integer  "old_acs_set_id"
    t.string   "guid"
    t.datetime "updated_at"
    t.string   "organization_id"
    t.string   "acs_set_id"
    t.boolean  "transfer_from_low",   default: false
  end

  create_table "ais_consent_marking_structures", force: :cascade do |t|
    t.string   "consent"
    t.boolean  "proprietary"
    t.string   "color"
    t.string   "stix_id"
    t.string   "stix_marking_id"
    t.string   "guid"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low", default: false
  end

  create_table "ais_statistics", force: :cascade do |t|
    t.string   "stix_package_stix_id"
    t.string   "stix_package_original_id"
    t.string   "uploaded_file_id"
    t.string   "feeds"
    t.string   "messages"
    t.string   "ais_uid"
    t.string   "guid"
    t.integer  "indicator_amount"
    t.boolean  "flare_in_status"
    t.boolean  "ciap_status"
    t.boolean  "ecis_status"
    t.boolean  "flare_out_status"
    t.boolean  "ecis_status_hr"
    t.boolean  "flare_out_status_hr"
    t.datetime "dissemination_time"
    t.datetime "dissemination_time_hr"
    t.datetime "received_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ais_statistics", ["ais_uid"], name: "index_ais_statistics_on_ais_uid"
  add_index "ais_statistics", ["guid"], name: "index_ais_statistics_on_guid"
  add_index "ais_statistics", ["updated_at"], name: "index_ais_statistics_on_updated_at"

  create_table "api_logs", force: :cascade do |t|
    t.string   "action"
    t.string   "controller"
    t.text     "uri"
    t.string   "user_guid"
    t.integer  "count"
    t.string   "query_source_entity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "attack_patterns", force: :cascade do |t|
    t.string   "stix_id"
    t.string   "title"
    t.string   "title_c"
    t.text     "description"
    t.string   "description_c"
    t.string   "description_normalized"
    t.string   "capec_id"
    t.string   "capec_id_c"
    t.string   "portion_marking"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "created_by_user_guid"
    t.string   "updated_by_user_guid"
    t.string   "created_by_organization_guid"
    t.string   "updated_by_organization_guid"
    t.datetime "stix_timestamp"
    t.boolean  "read_only",                    default: false
    t.boolean  "is_mifr",                      default: false
    t.boolean  "is_ciscp",                     default: false
    t.string   "feeds"
  end

  add_index "attack_patterns", ["capec_id"], name: "index_attack_patterns_on_capec_id"
  add_index "attack_patterns", ["description_normalized"], name: "index_attack_patterns_on_description_normalized"
  add_index "attack_patterns", ["guid"], name: "index_attack_patterns_on_guid"
  add_index "attack_patterns", ["stix_id"], name: "index_attack_patterns_on_stix_id"
  add_index "attack_patterns", ["title"], name: "index_attack_patterns_on_title"
  add_index "attack_patterns", ["updated_at"], name: "index_attack_patterns_on_updated_at"

  create_table "audit_logs", force: :cascade do |t|
    t.string   "message"
    t.text     "details"
    t.string   "audit_type"
    t.string   "old_justification"
    t.datetime "event_time"
    t.string   "user_guid"
    t.string   "system_guid"
    t.string   "item_type_audited"
    t.string   "item_guid_audited"
    t.string   "guid"
    t.string   "audit_subtype"
    t.text     "justification"
  end

  add_index "audit_logs", ["item_type_audited", "item_guid_audited"], name: "index_audit_logs_on_item_type_audited_and_item_guid_audited"

  create_table "authentication_logs", force: :cascade do |t|
    t.text     "info"
    t.string   "event"
    t.string   "access_mode"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remote_ip"
  end

  create_table "avp_messages", force: :cascade do |t|
    t.text     "prohibited"
    t.text     "avp_errors"
    t.string   "guid"
    t.boolean  "avp_valid"
    t.datetime "timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "avp_messages", ["guid"], name: "index_avp_messages_on_guid"
  add_index "avp_messages", ["updated_at"], name: "index_avp_messages_on_updated_at"

  create_table "badge_statuses", force: :cascade do |t|
    t.string   "badge_name"
    t.string   "badge_status"
    t.string   "remote_object_id"
    t.string   "remote_object_type"
    t.string   "guid"
    t.string   "created_by_user_guid"
    t.string   "created_by_organization_guid"
    t.string   "updated_by_user_guid"
    t.string   "updated_by_organization_guid"
    t.boolean  "system",                       default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",            default: false
  end

  add_index "badge_statuses", ["guid"], name: "index_badge_statuses_on_guid"

  create_table "contributing_sources", force: :cascade do |t|
    t.string   "organization_names"
    t.string   "countries"
    t.string   "administrative_areas"
    t.string   "stix_package_stix_id"
    t.string   "guid"
    t.string   "organization_info"
    t.boolean  "is_federal"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",    default: false
  end

  add_index "contributing_sources", ["updated_at"], name: "index_contributing_sources_on_updated_at"

  create_table "course_of_actions", force: :cascade do |t|
    t.string   "title"
    t.string   "title_c"
    t.text     "description"
    t.string   "description_c"
    t.string   "stix_id"
    t.string   "portion_marking"
    t.datetime "stix_timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "created_by_user_guid"
    t.string   "updated_by_user_guid"
    t.string   "created_by_organization_guid"
    t.string   "updated_by_organization_guid"
    t.integer  "old_acs_set_id"
    t.boolean  "read_only",                    default: false
    t.string   "description_normalized"
    t.boolean  "is_ciscp",                     default: false
    t.boolean  "is_mifr",                      default: false
    t.string   "feeds"
    t.string   "acs_set_id"
  end

  add_index "course_of_actions", ["guid"], name: "index_course_of_actions_on_guid"
  add_index "course_of_actions", ["stix_id"], name: "index_course_of_actions_on_stix_id"
  add_index "course_of_actions", ["updated_at"], name: "index_course_of_actions_on_updated_at"

  create_table "cybox_addresses", force: :cascade do |t|
    t.string   "address_value_raw"
    t.string   "address_value_normalized"
    t.string   "category"
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.decimal  "ip_value_calculated_start",              precision: 10
    t.decimal  "ip_value_calculated_end",                precision: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "iso_country_code"
    t.string   "com_threat_score"
    t.string   "gov_threat_score"
    t.string   "agencies_sensors_seen_on",  limit: 1000
    t.string   "first_date_seen_raw"
    t.datetime "first_date_seen"
    t.string   "last_date_seen_raw"
    t.datetime "last_date_seen"
    t.string   "combined_score"
    t.string   "category_list",             limit: 500
    t.string   "portion_marking"
    t.integer  "gfi_id_old"
    t.boolean  "read_only",                                             default: false
    t.boolean  "is_source"
    t.boolean  "is_destination"
    t.boolean  "is_spoofed"
    t.string   "address_condition",                                     default: "Equals"
    t.boolean  "is_ciscp",                                              default: false
    t.boolean  "is_mifr",                                               default: false
    t.string   "feeds"
  end

  add_index "cybox_addresses", ["address_value_normalized"], name: "index_cybox_addresses_on_address_value_normalized"
  add_index "cybox_addresses", ["cybox_object_id"], name: "index_cybox_addresses_on_cybox_object_id"
  add_index "cybox_addresses", ["gfi_id_old"], name: "index_cybox_addresses_on_gfi_id_old"
  add_index "cybox_addresses", ["guid"], name: "index_cybox_addresses_on_guid"
  add_index "cybox_addresses", ["updated_at"], name: "index_cybox_addresses_on_updated_at"

  create_table "cybox_custom_objects", force: :cascade do |t|
    t.string   "custom_name"
    t.string   "string"
    t.string   "string_description"
    t.string   "cybox_object_id"
    t.string   "cybox_hash"
    t.string   "user_guid"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cybox_custom_objects", ["cybox_object_id"], name: "index_cybox_custom_objects_on_cybox_object_id"

  create_table "cybox_dns_queries", force: :cascade do |t|
    t.string   "guid"
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "portion_marking"
    t.string   "question_normalized_cache"
    t.string   "answer_normalized_cache"
    t.string   "authority_normalized_cache"
    t.string   "additional_normalized_cache"
    t.boolean  "is_reference"
    t.boolean  "read_only",                   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_ciscp",                    default: false
    t.boolean  "is_mifr",                     default: false
    t.string   "feeds"
  end

  add_index "cybox_dns_queries", ["cybox_object_id"], name: "index_cybox_dns_queries_on_cybox_object_id"
  add_index "cybox_dns_queries", ["guid"], name: "index_cybox_dns_queries_on_guid"
  add_index "cybox_dns_queries", ["updated_at"], name: "index_cybox_dns_queries_on_updated_at"

  create_table "cybox_dns_records", force: :cascade do |t|
    t.string   "address_class",              default: "IN"
    t.string   "address_value_normalized"
    t.string   "address_value_raw"
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "description"
    t.string   "domain_normalized"
    t.string   "domain_raw"
    t.string   "entry_type",                 default: "A"
    t.datetime "queried_date"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "legacy_record_name"
    t.string   "legacy_record_type"
    t.integer  "legacy_ttl"
    t.string   "legacy_flags"
    t.integer  "legacy_data_length"
    t.text     "legacy_record_data"
    t.string   "portion_marking"
    t.integer  "gfi_id_old"
    t.boolean  "read_only",                  default: false
    t.string   "address_value_normalized_c"
    t.string   "address_class_c"
    t.string   "domain_normalized_c"
    t.string   "entry_type_c"
    t.string   "queried_date_c"
    t.string   "address_cybox_object_id"
    t.string   "domain_cybox_object_id"
    t.string   "record_name"
    t.string   "record_type"
    t.string   "ttl"
    t.string   "flags"
    t.string   "data_length"
    t.string   "record_name_c"
    t.string   "record_type_c"
    t.string   "ttl_c"
    t.string   "flags_c"
    t.string   "data_length_c"
    t.boolean  "is_ciscp",                   default: false
    t.boolean  "is_mifr",                    default: false
    t.string   "feeds"
  end

  add_index "cybox_dns_records", ["address_value_normalized"], name: "index_cybox_dns_records_on_address_value_normalized"
  add_index "cybox_dns_records", ["cybox_object_id"], name: "index_cybox_dns_records_on_cybox_object_id"
  add_index "cybox_dns_records", ["domain_normalized"], name: "index_cybox_dns_records_on_domain_normalized"
  add_index "cybox_dns_records", ["gfi_id_old"], name: "index_cybox_dns_records_on_gfi_id_old"
  add_index "cybox_dns_records", ["guid"], name: "index_cybox_dns_records_on_guid"
  add_index "cybox_dns_records", ["updated_at"], name: "index_cybox_dns_records_on_updated_at"

  create_table "cybox_domains", force: :cascade do |t|
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "name_raw"
    t.string   "name_condition",                        default: "Equals"
    t.string   "Equals"
    t.string   "name_normalized"
    t.string   "name_type",                             default: "FQDN",   null: false
    t.string   "root_domain"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "iso_country_code"
    t.string   "com_threat_score"
    t.string   "gov_threat_score"
    t.string   "agencies_sensors_seen_on", limit: 1000
    t.string   "first_date_seen_raw"
    t.datetime "first_date_seen"
    t.string   "last_date_seen_raw"
    t.datetime "last_date_seen"
    t.string   "combined_score"
    t.string   "category_list",            limit: 500
    t.string   "portion_marking"
    t.integer  "gfi_id_old"
    t.boolean  "read_only",                             default: false
    t.boolean  "is_ciscp",                              default: false
    t.boolean  "is_mifr",                               default: false
    t.string   "feeds"
  end

  add_index "cybox_domains", ["cybox_object_id"], name: "index_cybox_domains_on_cybox_object_id"
  add_index "cybox_domains", ["gfi_id_old"], name: "index_cybox_domains_on_gfi_id_old"
  add_index "cybox_domains", ["guid"], name: "index_cybox_domains_on_guid"
  add_index "cybox_domains", ["updated_at"], name: "index_cybox_domains_on_updated_at"

  create_table "cybox_email_messages", force: :cascade do |t|
    t.datetime "created_at"
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.datetime "email_date"
    t.boolean  "from_is_spoofed",                       default: false
    t.string   "from_raw"
    t.string   "from_normalized"
    t.string   "message_id"
    t.text     "raw_body"
    t.text     "raw_header"
    t.string   "reply_to_raw"
    t.string   "reply_to_normalized"
    t.boolean  "sender_is_spoofed",                     default: false
    t.string   "sender_raw"
    t.string   "sender_normalized"
    t.datetime "updated_at"
    t.string   "x_mailer"
    t.string   "x_originating_ip"
    t.string   "guid"
    t.string   "from_cybox_object_id"
    t.string   "reply_to_cybox_object_id"
    t.string   "sender_cybox_object_id"
    t.string   "portion_marking"
    t.integer  "gfi_id_old"
    t.boolean  "read_only",                             default: false
    t.string   "from_normalized_c"
    t.string   "sender_normalized_c"
    t.string   "reply_to_normalized_c"
    t.string   "subject_c"
    t.string   "email_date_c"
    t.string   "raw_body_c"
    t.string   "raw_header_c"
    t.string   "message_id_c"
    t.string   "x_mailer_c"
    t.string   "x_originating_ip_c"
    t.string   "subject_condition",                     default: "Equals"
    t.string   "x_ip_cybox_object_id"
    t.boolean  "is_ciscp",                              default: false
    t.boolean  "is_mifr",                               default: false
    t.string   "subject",                  limit: 4000
    t.string   "feeds"
  end

  add_index "cybox_email_messages", ["cybox_object_id"], name: "index_cybox_email_messages_on_cybox_object_id"
  add_index "cybox_email_messages", ["gfi_id_old"], name: "index_cybox_email_messages_on_gfi_id_old"
  add_index "cybox_email_messages", ["guid"], name: "index_cybox_email_messages_on_guid"
  add_index "cybox_email_messages", ["updated_at"], name: "index_cybox_email_messages_on_updated_at"

  create_table "cybox_file_hashes", force: :cascade do |t|
    t.datetime "created_at"
    t.string   "cybox_file_id"
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "fuzzy_hash_value"
    t.string   "fuzzy_hash_value_normalized"
    t.string   "hash_condition",                 default: "Equals"
    t.string   "hash_type"
    t.string   "hash_type_vocab_name"
    t.string   "hash_type_vocab_ref"
    t.string   "simple_hash_value"
    t.string   "simple_hash_value_normalized"
    t.datetime "updated_at"
    t.string   "guid"
    t.boolean  "read_only",                      default: false
    t.string   "simple_hash_value_normalized_c"
    t.string   "fuzzy_hash_value_normalized_c"
    t.boolean  "is_ciscp",                       default: false
    t.boolean  "is_mifr",                        default: false
    t.string   "feeds"
  end

  add_index "cybox_file_hashes", ["cybox_file_id"], name: "index_cybox_file_hashes_on_cybox_file_id"
  add_index "cybox_file_hashes", ["cybox_object_id"], name: "index_cybox_file_hashes_on_cybox_object_id"
  add_index "cybox_file_hashes", ["fuzzy_hash_value_normalized"], name: "index_cybox_file_hashes_on_fuzzy_hash_value_normalized"
  add_index "cybox_file_hashes", ["guid"], name: "index_cybox_file_hashes_on_guid"
  add_index "cybox_file_hashes", ["simple_hash_value_normalized"], name: "index_cybox_file_hashes_on_simple_hash_value_normalized"

  create_table "cybox_files", force: :cascade do |t|
    t.datetime "created_at"
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "file_extension"
    t.string   "file_name_condition",                         default: "Equals"
    t.string   "file_path"
    t.string   "file_path_condition",                         default: "Equals"
    t.string   "size_in_bytes_condition",                     default: "Equals"
    t.datetime "updated_at"
    t.string   "guid"
    t.text     "legacy_file_type"
    t.text     "legacy_registry_edits"
    t.string   "legacy_av_signature_mcafee"
    t.string   "legacy_av_signature_microsoft"
    t.string   "legacy_av_signature_symantec"
    t.string   "legacy_av_signature_trendmicro"
    t.string   "legacy_av_signature_kaspersky"
    t.datetime "legacy_compiled_at"
    t.string   "legacy_compiler_type"
    t.text     "legacy_cve"
    t.text     "legacy_keywords"
    t.text     "legacy_mutex"
    t.string   "legacy_packer"
    t.string   "legacy_xor_key"
    t.string   "legacy_motif_name"
    t.string   "legacy_motif_size"
    t.string   "legacy_composite_hash"
    t.string   "legacy_command_line"
    t.string   "portion_marking"
    t.integer  "gfi_id_old"
    t.boolean  "read_only",                                   default: false
    t.string   "file_name_c"
    t.string   "file_path_c"
    t.string   "size_in_bytes_c"
    t.boolean  "is_ciscp",                                    default: false
    t.boolean  "is_mifr",                                     default: false
    t.string   "size_in_bytes"
    t.string   "file_name",                      limit: 4000
    t.string   "feeds"
  end

  add_index "cybox_files", ["cybox_object_id"], name: "index_cybox_files_on_cybox_object_id"
  add_index "cybox_files", ["gfi_id_old"], name: "index_cybox_files_on_gfi_id_old"
  add_index "cybox_files", ["guid"], name: "index_cybox_files_on_guid"
  add_index "cybox_files", ["updated_at"], name: "index_cybox_files_on_updated_at"

  create_table "cybox_hostnames", force: :cascade do |t|
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "hostname_raw"
    t.string   "hostname_condition",    default: "Equals"
    t.string   "hostname_normalized"
    t.string   "hostname_normalized_c"
    t.string   "naming_system"
    t.string   "naming_system_c"
    t.boolean  "is_domain_name",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "portion_marking"
    t.boolean  "read_only",             default: false
    t.boolean  "is_ciscp",              default: false
    t.boolean  "is_mifr",               default: false
    t.string   "feeds"
  end

  add_index "cybox_hostnames", ["cybox_object_id"], name: "index_cybox_hostnames_on_cybox_object_id"
  add_index "cybox_hostnames", ["guid"], name: "index_cybox_hostnames_on_guid"
  add_index "cybox_hostnames", ["updated_at"], name: "index_cybox_hostnames_on_updated_at"

  create_table "cybox_http_sessions", force: :cascade do |t|
    t.string   "cybox_object_id"
    t.string   "cybox_hash"
    t.string   "user_agent"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "domain_name"
    t.string   "port"
    t.string   "referer"
    t.string   "pragma"
    t.string   "portion_marking"
    t.boolean  "read_only",            default: false
    t.string   "user_agent_c"
    t.string   "domain_name_c"
    t.string   "port_c"
    t.string   "referer_c"
    t.string   "pragma_c"
    t.string   "user_agent_condition", default: "Equals"
    t.boolean  "is_ciscp",             default: false
    t.boolean  "is_mifr",              default: false
    t.string   "feeds"
  end

  add_index "cybox_http_sessions", ["cybox_object_id"], name: "index_cybox_http_sessions_on_cybox_object_id"
  add_index "cybox_http_sessions", ["guid"], name: "index_cybox_http_sessions_on_guid"
  add_index "cybox_http_sessions", ["updated_at"], name: "index_cybox_http_sessions_on_updated_at"

  create_table "cybox_links", force: :cascade do |t|
    t.datetime "created_at"
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "label"
    t.string   "uri_object_id"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "portion_marking"
    t.boolean  "read_only",       default: false
    t.string   "label_c"
    t.string   "label_condition", default: "Equals"
    t.boolean  "is_ciscp",        default: false
    t.boolean  "is_mifr",         default: false
    t.string   "feeds"
  end

  add_index "cybox_links", ["cybox_object_id"], name: "index_cybox_links_on_cybox_object_id"
  add_index "cybox_links", ["guid"], name: "index_cybox_links_on_guid"
  add_index "cybox_links", ["updated_at"], name: "index_cybox_links_on_updated_at"
  add_index "cybox_links", ["uri_object_id"], name: "index_cybox_links_on_uri_object_id"

  create_table "cybox_mutexes", force: :cascade do |t|
    t.string   "cybox_object_id"
    t.string   "cybox_hash"
    t.string   "name"
    t.string   "name_condition",  default: "Equals"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "portion_marking"
    t.boolean  "read_only",       default: false
    t.boolean  "is_ciscp",        default: false
    t.boolean  "is_mifr",         default: false
    t.string   "feeds"
  end

  add_index "cybox_mutexes", ["cybox_object_id"], name: "index_cybox_mutexes_on_cybox_object_id"
  add_index "cybox_mutexes", ["guid"], name: "index_cybox_mutexes_on_guid"
  add_index "cybox_mutexes", ["updated_at"], name: "index_cybox_mutexes_on_updated_at"

  create_table "cybox_network_connections", force: :cascade do |t|
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "dest_socket_address"
    t.boolean  "dest_socket_is_spoofed",     default: false
    t.string   "dest_socket_port"
    t.string   "old_dest_socket_protocol"
    t.string   "source_socket_address"
    t.boolean  "source_socket_is_spoofed",   default: false
    t.string   "source_socket_port"
    t.string   "old_source_socket_protocol"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "dest_socket_hostname"
    t.string   "source_socket_hostname"
    t.string   "layer3_protocol"
    t.string   "layer4_protocol"
    t.string   "layer7_protocol"
    t.string   "portion_marking"
    t.boolean  "read_only",                  default: false
    t.string   "dest_socket_address_c"
    t.string   "dest_socket_port_c"
    t.string   "source_socket_address_c"
    t.string   "source_socket_port_c"
    t.string   "layer3_protocol_c"
    t.string   "layer4_protocol_c"
    t.string   "layer7_protocol_c"
    t.string   "dest_socket_hostname_c"
    t.string   "source_socket_hostname_c"
    t.string   "source_socket_address_id"
    t.string   "dest_socket_address_id"
    t.boolean  "is_ciscp",                   default: false
    t.boolean  "is_mifr",                    default: false
    t.string   "feeds"
  end

  add_index "cybox_network_connections", ["cybox_object_id"], name: "index_cybox_network_connections_on_cybox_object_id"
  add_index "cybox_network_connections", ["guid"], name: "index_cybox_network_connections_on_guid"
  add_index "cybox_network_connections", ["updated_at"], name: "index_cybox_network_connections_on_updated_at"

  create_table "cybox_observables", force: :cascade do |t|
    t.string   "composite_operator"
    t.string   "cybox_object_id"
    t.boolean  "is_composite",       default: false
    t.boolean  "is_imported",        default: false
    t.boolean  "is_negated",         default: false
    t.integer  "old_parent_id"
    t.string   "remote_object_id"
    t.string   "remote_object_type"
    t.string   "stix_indicator_id"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.boolean  "read_only",          default: false
    t.boolean  "is_ciscp",           default: false
    t.boolean  "is_mifr",            default: false
    t.string   "feeds"
    t.string   "parent_id"
  end

  add_index "cybox_observables", ["cybox_object_id"], name: "index_cybox_observables_on_cybox_object_id"
  add_index "cybox_observables", ["guid"], name: "index_cybox_observables_on_guid"
  add_index "cybox_observables", ["parent_id"], name: "index_cybox_observables_on_parent_id"
  add_index "cybox_observables", ["remote_object_id"], name: "index_cybox_observables_on_remote_object_id"
  add_index "cybox_observables", ["stix_indicator_id"], name: "index_cybox_observables_on_stix_indicator_id"
  add_index "cybox_observables", ["updated_at"], name: "index_cybox_observables_on_updated_at"

  create_table "cybox_ports", force: :cascade do |t|
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "port"
    t.string   "port_c"
    t.string   "layer4_protocol"
    t.string   "layer4_protocol_c"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "portion_marking"
    t.boolean  "read_only",         default: false
    t.boolean  "is_ciscp",          default: false
    t.boolean  "is_mifr",           default: false
    t.string   "feeds"
  end

  add_index "cybox_ports", ["cybox_object_id"], name: "index_cybox_ports_on_cybox_object_id"
  add_index "cybox_ports", ["guid"], name: "index_cybox_ports_on_guid"
  add_index "cybox_ports", ["updated_at"], name: "index_cybox_ports_on_updated_at"

  create_table "cybox_socket_addresses", force: :cascade do |t|
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "addresses_normalized_cache"
    t.string   "hostnames_normalized_cache"
    t.string   "ports_normalized_cache"
    t.string   "name_condition"
    t.string   "apply_condition"
    t.string   "guid"
    t.string   "portion_marking"
    t.boolean  "is_reference"
    t.boolean  "read_only",                  default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_ciscp",                   default: false
    t.boolean  "is_mifr",                    default: false
    t.string   "feeds"
  end

  add_index "cybox_socket_addresses", ["cybox_object_id"], name: "index_cybox_socket_addresses_on_cybox_object_id"
  add_index "cybox_socket_addresses", ["guid"], name: "index_cybox_socket_addresses_on_guid"
  add_index "cybox_socket_addresses", ["updated_at"], name: "index_cybox_socket_addresses_on_updated_at"

  create_table "cybox_uris", force: :cascade do |t|
    t.datetime "created_at"
    t.string   "cybox_hash"
    t.string   "cybox_object_id"
    t.string   "old_label"
    t.datetime "updated_at"
    t.string   "uri_type",                          default: "URL"
    t.string   "guid"
    t.string   "portion_marking"
    t.boolean  "read_only",                         default: false
    t.text     "uri_normalized"
    t.text     "uri_raw"
    t.string   "uri_normalized_sha256"
    t.string   "uri_condition",                     default: "Equals"
    t.boolean  "is_ciscp",                          default: false
    t.string   "uri_short",             limit: 255
    t.boolean  "is_mifr",                           default: false
    t.string   "feeds"
  end

  add_index "cybox_uris", ["cybox_object_id"], name: "index_cybox_uris_on_cybox_object_id"
  add_index "cybox_uris", ["guid"], name: "index_cybox_uris_on_guid"
  add_index "cybox_uris", ["updated_at"], name: "index_cybox_uris_on_updated_at"
  add_index "cybox_uris", ["uri_short"], name: "index_cybox_uris_on_uri_short"

  create_table "cybox_win_registry_keys", force: :cascade do |t|
    t.string   "cybox_object_id"
    t.string   "cybox_hash"
    t.string   "hive"
    t.string   "key"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "portion_marking"
    t.boolean  "read_only",       default: false
    t.string   "hive_c"
    t.string   "key_c"
    t.string   "hive_condition",  default: "Equals"
    t.boolean  "is_ciscp",        default: false
    t.boolean  "is_mifr",         default: false
    t.string   "feeds"
  end

  add_index "cybox_win_registry_keys", ["cybox_object_id"], name: "index_cybox_win_registry_keys_on_cybox_object_id"
  add_index "cybox_win_registry_keys", ["guid"], name: "index_cybox_win_registry_keys_on_guid"
  add_index "cybox_win_registry_keys", ["updated_at"], name: "index_cybox_win_registry_keys_on_updated_at"

  create_table "cybox_win_registry_values", force: :cascade do |t|
    t.string   "cybox_object_id"
    t.text     "reg_name"
    t.text     "reg_value"
    t.string   "guid"
    t.string   "cybox_hash"
    t.boolean  "read_only",       default: false
    t.string   "reg_name_c"
    t.string   "reg_value_c"
    t.string   "data_condition",  default: "Equals"
    t.datetime "updated_at"
  end

  add_index "cybox_win_registry_values", ["cybox_object_id"], name: "index_cybox_win_registry_values_on_cybox_object_id"

  create_table "disseminated_feeds", force: :cascade do |t|
    t.integer "disseminate_id"
    t.string  "feed"
  end

  create_table "disseminated_records", force: :cascade do |t|
    t.string   "stix_id",         null: false
    t.datetime "xml_updated_at"
    t.datetime "disseminated_at"
  end

  add_index "disseminated_records", ["xml_updated_at"], name: "index_disseminated_records_on_xml_updated_at"

  create_table "dissemination_queue", force: :cascade do |t|
    t.string   "original_input_id"
    t.string   "finished_feeds"
    t.datetime "updated"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dms_labels", force: :cascade do |t|
    t.datetime "dms_record_date"
    t.integer  "dms_record_id"
    t.boolean  "is_vetted",          default: false
    t.string   "remote_object_id"
    t.string   "remote_object_type"
    t.string   "source"
    t.integer  "version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dms_labels", ["dms_record_id"], name: "index_dms_labels_on_dms_record_id"

  create_table "dns_query_questions", force: :cascade do |t|
    t.string   "dns_query_id"
    t.string   "question_id"
    t.string   "guid"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low", default: false
  end

  add_index "dns_query_questions", ["dns_query_id"], name: "index_dns_query_questions_on_dns_query_id"
  add_index "dns_query_questions", ["guid"], name: "index_dns_query_questions_on_guid"
  add_index "dns_query_questions", ["question_id"], name: "index_dns_query_questions_on_question_id"

  create_table "dns_query_resource_records", force: :cascade do |t|
    t.string   "dns_query_id"
    t.string   "resource_record_id"
    t.string   "guid"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",  default: false
  end

  add_index "dns_query_resource_records", ["dns_query_id"], name: "index_dns_query_resource_records_on_dns_query_id"
  add_index "dns_query_resource_records", ["guid"], name: "index_dns_query_resource_records_on_guid"
  add_index "dns_query_resource_records", ["resource_record_id"], name: "index_dns_query_resource_records_on_resource_record_id"

  create_table "download_temp", force: :cascade do |t|
    t.string "user_guid", null: false
    t.binary "download",  null: false
  end

  add_index "download_temp", ["user_guid"], name: "index_download_temp_on_user_guid"

  create_table "email_files", force: :cascade do |t|
    t.string   "email_message_id"
    t.string   "cybox_file_id"
    t.string   "guid"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low", default: false
  end

  create_table "email_links", force: :cascade do |t|
    t.integer  "old_email_message_id"
    t.integer  "old_link_id"
    t.string   "guid"
    t.datetime "updated_at"
    t.string   "email_message_id"
    t.string   "link_id"
    t.boolean  "transfer_from_low",    default: false
  end

  create_table "email_uris", force: :cascade do |t|
    t.integer  "old_email_message_id"
    t.integer  "old_uri_id"
    t.string   "guid"
    t.datetime "updated_at"
    t.string   "email_message_id"
    t.string   "uri_id"
    t.boolean  "transfer_from_low",    default: false
  end

  create_table "error_messages", force: :cascade do |t|
    t.text     "admin_description"
    t.boolean  "is_warning",        default: false
    t.integer  "old_source_id"
    t.string   "source_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.string   "guid"
    t.string   "source_id"
    t.boolean  "transfer_from_low", default: false
  end

  add_index "error_messages", ["source_id"], name: "index_error_messages_on_source_id"

  create_table "exploit_target_coas", force: :cascade do |t|
    t.string   "stix_exploit_target_id"
    t.string   "stix_course_of_action_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "user_guid"
    t.boolean  "transfer_from_low",        default: false
  end

  add_index "exploit_target_coas", ["guid"], name: "index_exploit_target_coas_on_guid"
  add_index "exploit_target_coas", ["stix_course_of_action_id"], name: "index_exploit_target_coas_on_stix_course_of_action_id"
  add_index "exploit_target_coas", ["stix_exploit_target_id"], name: "index_exploit_target_coas_on_stix_exploit_target_id"

  create_table "exploit_target_packages", force: :cascade do |t|
    t.string   "stix_exploit_target_id"
    t.string   "stix_package_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "user_guid"
    t.boolean  "transfer_from_low",      default: false
  end

  add_index "exploit_target_packages", ["guid"], name: "index_exploit_target_packages_on_guid"
  add_index "exploit_target_packages", ["stix_exploit_target_id"], name: "index_exploit_target_packages_on_stix_exploit_target_id"
  add_index "exploit_target_packages", ["stix_package_id"], name: "index_exploit_target_packages_on_stix_package_id"

  create_table "exploit_target_vulnerabilities", force: :cascade do |t|
    t.string   "stix_exploit_target_id"
    t.string   "vulnerability_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "user_guid"
    t.boolean  "transfer_from_low",      default: false
  end

  add_index "exploit_target_vulnerabilities", ["guid"], name: "index_exploit_target_vulnerabilities_on_guid"
  add_index "exploit_target_vulnerabilities", ["stix_exploit_target_id"], name: "index_exploit_target_vulnerabilities_on_stix_exploit_target_id"
  add_index "exploit_target_vulnerabilities", ["vulnerability_guid"], name: "index_exploit_target_vulnerabilities_on_vulnerability_guid"

  create_table "exploit_targets", force: :cascade do |t|
    t.string   "stix_id"
    t.string   "portion_marking"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "created_by_user_guid"
    t.string   "updated_by_user_guid"
    t.string   "created_by_organization_guid"
    t.string   "updated_by_organization_guid"
    t.integer  "old_acs_set_id"
    t.datetime "stix_timestamp"
    t.boolean  "read_only",                    default: false
    t.boolean  "is_ciscp",                     default: false
    t.boolean  "is_mifr",                      default: false
    t.string   "feeds"
    t.string   "acs_set_id"
  end

  add_index "exploit_targets", ["guid"], name: "index_exploit_targets_on_guid"
  add_index "exploit_targets", ["stix_id"], name: "index_exploit_targets_on_stix_id"
  add_index "exploit_targets", ["updated_at"], name: "index_exploit_targets_on_updated_at"

  create_table "exported_indicators", force: :cascade do |t|
    t.string   "system"
    t.string   "color"
    t.string   "guid"
    t.datetime "exported_at"
    t.text     "description"
    t.string   "indicator_id"
    t.string   "user_id"
    t.datetime "detasked_at"
    t.datetime "updated_at"
    t.string   "status"
    t.string   "sid2"
    t.string   "comments_normalized"
    t.datetime "date_added"
    t.string   "event"
    t.string   "event_classification"
    t.string   "nai"
    t.string   "nai_classification"
    t.string   "special_instructions"
    t.string   "sid"
    t.string   "reference"
    t.string   "cs_regex"
    t.string   "clear_text"
    t.string   "signature_location"
    t.string   "ps_regex"
    t.string   "observable_value"
    t.string   "indicator_title"
    t.string   "indicator_stix_id"
    t.string   "indicator_type"
    t.string   "indicator_classification"
    t.string   "indicator_type_classification"
    t.string   "username"
    t.text     "comments"
    t.boolean  "transfer_from_low",             default: false
  end

  add_index "exported_indicators", ["updated_at"], name: "index_exported_indicators_on_updated_at"

  create_table "further_sharings", force: :cascade do |t|
    t.string   "scope",                                        null: false
    t.string   "effect",                                       null: false
    t.string   "isa_assertion_structure_guid"
    t.string   "guid"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",            default: false
  end

  create_table "gfis", force: :cascade do |t|
    t.text    "gfi_source_name"
    t.text    "gfi_action_name"
    t.text    "gfi_action_name_class"
    t.text    "gfi_action_name_subclass"
    t.text    "gfi_ps_regex"
    t.text    "gfi_ps_regex_class"
    t.text    "gfi_ps_regex_subclass"
    t.text    "gfi_cs_regex"
    t.text    "gfi_cs_regex_class"
    t.text    "gfi_cs_regex_subclass"
    t.text    "gfi_exp_sig_loc"
    t.text    "gfi_exp_sig_loc_class"
    t.text    "gfi_exp_sig_loc_subclass"
    t.integer "gfi_bluesmoke_id"
    t.integer "gfi_uscert_sid"
    t.text    "gfi_notes"
    t.text    "gfi_notes_class"
    t.text    "gfi_notes_subclass"
    t.text    "gfi_status"
    t.text    "gfi_uscert_doc"
    t.text    "gfi_uscert_doc_class"
    t.text    "gfi_uscert_doc_subclass"
    t.text    "gfi_special_inst"
    t.text    "gfi_special_inst_class"
    t.text    "gfi_special_inst_subclass"
    t.text    "gfi_type"
    t.text    "old_guid"
    t.string  "guid"
    t.string  "remote_object_id"
    t.string  "remote_object_type"
  end

  add_index "gfis", ["remote_object_id"], name: "index_gfis_on_remote_object_id"

  create_table "groups", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
  end

  add_index "groups", ["guid"], name: "index_groups_on_guid"

  create_table "groups_permissions", force: :cascade do |t|
    t.integer  "group_id"
    t.integer  "permission_id"
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.string   "guid"
  end

  add_index "groups_permissions", ["guid"], name: "index_groups_permissions_on_guid"

  create_table "human_review_fields", force: :cascade do |t|
    t.boolean  "is_changed",            default: false
    t.integer  "human_review_id"
    t.string   "object_field",                          null: false
    t.text     "object_field_revised"
    t.text     "object_field_original"
    t.string   "object_uid"
    t.string   "object_type"
    t.string   "object_sha2"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.boolean  "has_pii"
  end

  add_index "human_review_fields", ["human_review_id"], name: "index_human_review_fields_on_human_review_id"

  create_table "human_reviews", force: :cascade do |t|
    t.datetime "decided_at"
    t.string   "decided_by"
    t.string   "status",                         limit: 1, default: "N", null: false
    t.integer  "uploaded_file_id"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.integer  "human_review_fields_count",                default: 0
    t.integer  "comp_human_review_fields_count",           default: 0
  end

  create_table "id_mappings", force: :cascade do |t|
    t.string   "before_id"
    t.string   "after_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "id_mappings", ["after_id"], name: "index_id_mappings_on_after_id"
  add_index "id_mappings", ["before_id"], name: "index_id_mappings_on_before_id"

  create_table "indicator_ttps", force: :cascade do |t|
    t.string   "stix_ttp_id"
    t.string   "stix_indicator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "user_guid"
    t.boolean  "transfer_from_low", default: false
  end

  add_index "indicator_ttps", ["guid"], name: "index_indicator_ttps_on_guid"
  add_index "indicator_ttps", ["stix_indicator_id"], name: "index_indicator_ttps_on_stix_indicator_id"
  add_index "indicator_ttps", ["stix_ttp_id"], name: "index_indicator_ttps_on_stix_ttp_id"

  create_table "indicator_zips", force: :cascade do |t|
    t.integer "uploaded_file_id"
    t.integer "indicator_id"
  end

  add_index "indicator_zips", ["uploaded_file_id"], name: "index_indicator_zips_on_uploaded_file_id"

  create_table "indicators_course_of_actions", force: :cascade do |t|
    t.string   "stix_indicator_id"
    t.string   "course_of_action_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "user_guid"
    t.boolean  "transfer_from_low",   default: false
  end

  add_index "indicators_course_of_actions", ["course_of_action_id"], name: "index_indicators_course_of_actions_on_course_of_action_id"
  add_index "indicators_course_of_actions", ["guid"], name: "index_indicators_course_of_actions_on_guid"
  add_index "indicators_course_of_actions", ["stix_indicator_id"], name: "index_indicators_course_of_actions_on_stix_indicator_id"

  create_table "indicators_threat_actors", force: :cascade do |t|
    t.string   "threat_actor_id"
    t.string   "stix_indicator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "user_guid"
    t.boolean  "transfer_from_low", default: false
  end

  add_index "indicators_threat_actors", ["guid"], name: "index_indicators_threat_actors_on_guid"
  add_index "indicators_threat_actors", ["stix_indicator_id"], name: "index_indicators_threat_actors_on_stix_indicator_id"
  add_index "indicators_threat_actors", ["threat_actor_id"], name: "index_indicators_threat_actors_on_threat_actor_id"

  create_table "isa_assertion_structures", force: :cascade do |t|
    t.string   "cs_classification",       default: "U",    null: false
    t.string   "cs_countries"
    t.string   "cs_cui"
    t.string   "cs_entity"
    t.string   "cs_formal_determination"
    t.string   "cs_orgs"
    t.string   "cs_shargrp"
    t.string   "guid",                                     null: false
    t.boolean  "is_default_marking",      default: false,  null: false
    t.string   "privilege_default",       default: "deny", null: false
    t.boolean  "public_release",          default: false,  null: false
    t.string   "public_released_by"
    t.datetime "public_released_on"
    t.string   "stix_id",                                  null: false
    t.string   "stix_marking_id"
    t.string   "cs_info_caveat"
    t.string   "sharing_default"
    t.string   "classified_by"
    t.datetime "classified_on"
    t.string   "classification_reason"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",       default: false
  end

  create_table "isa_entity_caches", force: :cascade do |t|
    t.string   "admin_org",          default: "USA.DHS.US-CERT", null: false
    t.boolean  "ato_status",         default: true,              null: false
    t.string   "clearance",          default: "U",               null: false
    t.string   "country",            default: "USA",             null: false
    t.string   "distinguished_name"
    t.string   "duty_org",           default: "USA.DHS.US-CERT", null: false
    t.string   "entity_class",       default: "PE",              null: false
    t.string   "entity_type",        default: "GOV",             null: false
    t.string   "life_cycle_status",  default: "PROD",            null: false
    t.string   "user_guid",                                      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "access_groups"
    t.string   "guid"
    t.boolean  "transfer_from_low",  default: false
  end

  create_table "isa_marking_structures", force: :cascade do |t|
    t.datetime "data_item_created_at"
    t.string   "guid",                                 null: false
    t.string   "re_custodian",                         null: false
    t.string   "re_originator"
    t.string   "stix_id",                              null: false
    t.string   "stix_marking_id"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",    default: false
  end

  create_table "isa_privs", force: :cascade do |t|
    t.string   "action"
    t.string   "effect",                                    default: "deny", null: false
    t.string   "guid"
    t.string   "isa_assertion_structure_guid"
    t.string   "scope_countries",              limit: 1000
    t.string   "scope_entity"
    t.boolean  "scope_is_all",                              default: true,   null: false
    t.string   "scope_orgs"
    t.string   "scope_shargrp"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",                         default: false
  end

  add_index "isa_privs", ["guid"], name: "index_isa_privs_on_guid"
  add_index "isa_privs", ["isa_assertion_structure_guid"], name: "index_isa_privs_on_isa_assertion_structure_guid"

  create_table "layer_seven_connections", force: :cascade do |t|
    t.string   "guid"
    t.string   "cybox_hash"
    t.string   "portion_marking"
    t.string   "http_session_id"
    t.string   "dns_query_cache"
    t.boolean  "is_reference"
    t.boolean  "read_only",       default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "layer_seven_connections", ["guid"], name: "index_layer_seven_connections_on_guid"
  add_index "layer_seven_connections", ["updated_at"], name: "index_layer_seven_connections_on_updated_at"

  create_table "legacy_section_hashes", force: :cascade do |t|
    t.string   "indicator_guid"
    t.string   "hsh"
    t.string   "name"
    t.string   "ord"
    t.string   "size"
    t.string   "hash_type"
    t.string   "vsize"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "legacy_yara_rules", force: :cascade do |t|
    t.string  "name"
    t.integer "string_location"
    t.string  "string"
    t.text    "rule"
    t.string  "indicator_guid"
  end

  create_table "lsc_dns_queries", force: :cascade do |t|
    t.string   "layer_seven_connection_id"
    t.string   "dns_query_id"
    t.string   "guid"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",         default: false
  end

  add_index "lsc_dns_queries", ["dns_query_id"], name: "index_lsc_dns_queries_on_dns_query_id"
  add_index "lsc_dns_queries", ["guid"], name: "index_lsc_dns_queries_on_guid"
  add_index "lsc_dns_queries", ["layer_seven_connection_id"], name: "index_lsc_dns_queries_on_layer_seven_connection_id"

  create_table "nc_layer_seven_connections", force: :cascade do |t|
    t.string   "network_connection_id"
    t.string   "layer_seven_connection_id"
    t.string   "guid"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",         default: false
  end

  add_index "nc_layer_seven_connections", ["guid"], name: "index_nc_layer_seven_connections_on_guid"
  add_index "nc_layer_seven_connections", ["layer_seven_connection_id"], name: "index_nc_layer_seven_connections_on_layer_seven_connection_id"
  add_index "nc_layer_seven_connections", ["network_connection_id"], name: "index_nc_layer_seven_connections_on_network_connection_id"

  create_table "notes", force: :cascade do |t|
    t.string   "guid"
    t.string   "target_class"
    t.string   "target_guid"
    t.string   "user_guid"
    t.text     "note"
    t.string   "justification"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low", default: false
  end

  create_table "old_isa_marking_structures", force: :cascade do |t|
    t.string   "cs_classification"
    t.string   "cs_countries",            limit: 1000
    t.string   "cs_cui"
    t.string   "cs_entity"
    t.string   "cs_formal_determination"
    t.string   "cs_info_caveat"
    t.string   "cs_orgs"
    t.string   "cs_shargrp"
    t.string   "guid"
    t.string   "is_default_marking",                   default: "f",    null: false
    t.string   "is_reference",                         default: "f",    null: false
    t.string   "marking_model_type"
    t.string   "privilege_default",                    default: "deny", null: false
    t.boolean  "public_release",                       default: false,  null: false
    t.string   "public_released_by"
    t.datetime "public_released_on"
    t.string   "re_custodian"
    t.datetime "re_data_item_created_at"
    t.string   "re_originator"
    t.string   "stix_id"
    t.string   "stix_marking_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "old_isa_marking_structures", ["guid"], name: "index_old_isa_marking_structures_on_guid"
  add_index "old_isa_marking_structures", ["stix_id"], name: "index_old_isa_marking_structures_on_stix_id"
  add_index "old_isa_marking_structures", ["stix_marking_guid"], name: "index_old_isa_marking_structures_on_stix_marking_guid"

  create_table "old_isa_markings", force: :cascade do |t|
    t.string   "community_dissemination",   limit: 2000
    t.datetime "data_item_created_at"
    t.string   "dissemination_controls"
    t.string   "guid"
    t.string   "org_dissemination"
    t.boolean  "public_release",                         default: false, null: false
    t.string   "re_country",                limit: 2000
    t.string   "re_organization"
    t.string   "re_suborganization"
    t.string   "releasable_to"
    t.string   "stix_marking_id"
    t.string   "user_status_dissemination"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "old_isa_markings", ["stix_marking_id"], name: "index_old_isa_markings_on_stix_marking_id"

  create_table "old_stix_kill_chains", force: :cascade do |t|
    t.string  "kill_chain_id"
    t.string  "kill_chain_name"
    t.integer "ordinality"
    t.string  "phase_id"
    t.string  "phase_name"
    t.string  "remote_object_id"
    t.string  "remote_object_type"
    t.string  "guid"
  end

  add_index "old_stix_kill_chains", ["guid"], name: "index_old_stix_kill_chains_on_guid"
  add_index "old_stix_kill_chains", ["remote_object_id"], name: "index_old_stix_kill_chains_on_remote_object_id"

  create_table "organizations", force: :cascade do |t|
    t.integer  "r5_id"
    t.string   "guid"
    t.string   "long_name"
    t.string   "short_name"
    t.text     "contact_info"
    t.string   "category"
    t.integer  "releasability_mask",  default: 15
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "organization_token"
    t.integer  "old_acs_sets_org_id"
    t.string   "acs_sets_org_id"
    t.boolean  "transfer_from_low",   default: false
  end

  create_table "original_input", force: :cascade do |t|
    t.boolean  "old_is_attachment",    default: false, null: false
    t.string   "mime_type",                            null: false
    t.binary   "raw_content",                          null: false
    t.string   "remote_object_id"
    t.string   "remote_object_type"
    t.integer  "old_uploaded_file_id",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "sha2_hash"
    t.string   "input_category"
    t.string   "input_sub_category"
    t.string   "uploaded_file_id"
    t.boolean  "transfer_from_low",    default: false
  end

  add_index "original_input", ["guid"], name: "index_original_input_on_guid"
  add_index "original_input", ["remote_object_id"], name: "index_original_input_on_remote_object_id"
  add_index "original_input", ["uploaded_file_id"], name: "index_original_input_on_uploaded_file_id"

  create_table "original_input_id_mappings", force: :cascade do |t|
    t.integer "original_input_id"
    t.integer "ciap_id_mapping_id"
  end

  create_table "packages_course_of_actions", force: :cascade do |t|
    t.string   "stix_package_id"
    t.string   "course_of_action_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "user_guid"
    t.boolean  "transfer_from_low",   default: false
  end

  add_index "packages_course_of_actions", ["course_of_action_id"], name: "index_packages_course_of_actions_on_course_of_action_id"
  add_index "packages_course_of_actions", ["guid"], name: "index_packages_course_of_actions_on_guid"
  add_index "packages_course_of_actions", ["stix_package_id"], name: "index_packages_course_of_actions_on_stix_package_id"

  create_table "parameter_observables", force: :cascade do |t|
    t.string   "cybox_object_id"
    t.boolean  "is_imported",              default: false
    t.string   "remote_object_id"
    t.string   "remote_object_type"
    t.string   "stix_course_of_action_id"
    t.string   "user_guid"
    t.string   "guid"
    t.boolean  "read_only",                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "parameter_observables", ["cybox_object_id"], name: "index_parameter_observables_on_cybox_object_id"
  add_index "parameter_observables", ["guid"], name: "index_parameter_observables_on_guid"
  add_index "parameter_observables", ["remote_object_id"], name: "index_parameter_observables_on_remote_object_id"
  add_index "parameter_observables", ["stix_course_of_action_id"], name: "index_parameter_observables_on_stix_course_of_action_id"
  add_index "parameter_observables", ["updated_at"], name: "index_parameter_observables_on_updated_at"

  create_table "passwords", force: :cascade do |t|
    t.string   "password_hash"
    t.string   "password_salt"
    t.boolean  "requires_change", default: false
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pending_amqp_messages", force: :cascade do |t|
    t.boolean  "is_stix_xml",                   null: false
    t.string   "transfer_category"
    t.string   "repl_type"
    t.binary   "message_data",                  null: false
    t.binary   "string_props",                  null: false
    t.datetime "last_attempted"
    t.integer  "attempt_count",     default: 0, null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "pending_markings", force: :cascade do |t|
    t.string   "remote_object_type"
    t.string   "remote_object_guid"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "pending_markings", ["remote_object_guid"], name: "index_pending_markings_on_remote_object_guid"

  create_table "permissions", force: :cascade do |t|
    t.string   "name"
    t.string   "display_name"
    t.string   "description"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
  end

  add_index "permissions", ["guid"], name: "index_permissions_on_guid"

  create_table "question_uris", force: :cascade do |t|
    t.string   "question_id"
    t.string   "uri_id"
    t.string   "guid"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low", default: false
  end

  add_index "question_uris", ["guid"], name: "index_question_uris_on_guid"
  add_index "question_uris", ["question_id"], name: "index_question_uris_on_question_id"
  add_index "question_uris", ["uri_id"], name: "index_question_uris_on_uri_id"

  create_table "questions", force: :cascade do |t|
    t.string   "guid"
    t.string   "cybox_hash"
    t.string   "portion_marking"
    t.string   "qclass"
    t.string   "qtype"
    t.string   "qname_cache"
    t.boolean  "is_reference"
    t.boolean  "read_only",       default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_ciscp",        default: false
    t.boolean  "is_mifr",         default: false
    t.string   "feeds"
  end

  add_index "questions", ["guid"], name: "index_questions_on_guid"
  add_index "questions", ["updated_at"], name: "index_questions_on_updated_at"

  create_table "r5destinations", force: :cascade do |t|
    t.string  "r5table"
    t.integer "r5id"
    t.string  "r6table"
    t.integer "r6id"
  end

  create_table "r5tracking", force: :cascade do |t|
    t.string  "table"
    t.integer "old_id"
  end

  create_table "replications", force: :cascade do |t|
    t.string "version"
    t.string "url"
    t.string "api_key"
    t.string "api_key_hash"
    t.string "last_status"
    t.string "repl_type"
    t.date   "updated_at"
    t.date   "created_at"
  end

  create_table "reported_issues", force: :cascade do |t|
    t.string   "subject"
    t.string   "description"
    t.string   "user_guid"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "called_from"
  end

  create_table "resource_record_dns_records", force: :cascade do |t|
    t.string   "resource_record_id"
    t.string   "dns_record_id"
    t.string   "guid"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",  default: false
  end

  add_index "resource_record_dns_records", ["dns_record_id"], name: "index_resource_record_dns_records_on_dns_record_id"
  add_index "resource_record_dns_records", ["guid"], name: "index_resource_record_dns_records_on_guid"
  add_index "resource_record_dns_records", ["resource_record_id"], name: "index_resource_record_dns_records_on_resource_record_id"

  create_table "resource_records", force: :cascade do |t|
    t.string   "guid"
    t.string   "cybox_hash"
    t.string   "portion_marking"
    t.string   "record_type"
    t.string   "dns_record_cache"
    t.boolean  "is_reference"
    t.boolean  "read_only",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_ciscp",         default: false
    t.boolean  "is_mifr",          default: false
    t.string   "feeds"
  end

  add_index "resource_records", ["guid"], name: "index_resource_records_on_guid"
  add_index "resource_records", ["updated_at"], name: "index_resource_records_on_updated_at"

  create_table "search_logs", force: :cascade do |t|
    t.text     "query"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "simple_structures", force: :cascade do |t|
    t.string   "guid",                              null: false
    t.text     "statement",                         null: false
    t.string   "stix_id",                           null: false
    t.string   "stix_marking_id"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low", default: false
  end

  create_table "socket_address_addresses", force: :cascade do |t|
    t.string   "socket_address_id"
    t.string   "address_id"
    t.string   "guid"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low", default: false
  end

  add_index "socket_address_addresses", ["address_id"], name: "index_socket_address_addresses_on_address_id"
  add_index "socket_address_addresses", ["guid"], name: "index_socket_address_addresses_on_guid"
  add_index "socket_address_addresses", ["socket_address_id"], name: "index_socket_address_addresses_on_socket_address_id"

  create_table "socket_address_hostnames", force: :cascade do |t|
    t.string   "socket_address_id"
    t.string   "hostname_id"
    t.string   "guid"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low", default: false
  end

  add_index "socket_address_hostnames", ["guid"], name: "index_socket_address_hostnames_on_guid"
  add_index "socket_address_hostnames", ["hostname_id"], name: "index_socket_address_hostnames_on_hostname_id"
  add_index "socket_address_hostnames", ["socket_address_id"], name: "index_socket_address_hostnames_on_socket_address_id"

  create_table "socket_address_ports", force: :cascade do |t|
    t.string   "socket_address_id"
    t.string   "port_id"
    t.string   "guid"
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low", default: false
  end

  add_index "socket_address_ports", ["guid"], name: "index_socket_address_ports_on_guid"
  add_index "socket_address_ports", ["port_id"], name: "index_socket_address_ports_on_port_id"
  add_index "socket_address_ports", ["socket_address_id"], name: "index_socket_address_ports_on_socket_address_id"

  create_table "solr_index_time", force: :cascade do |t|
    t.datetime "last_updated"
  end

  create_table "staging_weather_map_data", id: false, force: :cascade do |t|
    t.string "ip_address"
    t.string "iso_country_code"
    t.string "com_threat_score"
    t.string "gov_threat_score"
    t.string "combined_score"
    t.string "agencies_sensors_seen_on", limit: 1000
    t.string "first_date_seen"
    t.string "last_date_seen"
    t.string "category_list",            limit: 1000
  end

  create_table "stix_confidences", force: :cascade do |t|
    t.string   "value",                              null: false
    t.text     "description"
    t.string   "source"
    t.boolean  "is_official",        default: false
    t.integer  "confidence_num",                     null: false
    t.datetime "created_at"
    t.datetime "stix_timestamp"
    t.string   "user_guid"
    t.string   "remote_object_type",                 null: false
    t.string   "remote_object_id",                   null: false
    t.string   "guid"
    t.boolean  "from_file",          default: false
    t.boolean  "transfer_from_low",  default: false
  end

  create_table "stix_indicators", force: :cascade do |t|
    t.string   "composite_operator"
    t.datetime "created_at"
    t.text     "description"
    t.string   "indicator_type"
    t.string   "indicator_type_vocab_name"
    t.string   "indicator_type_vocab_ref"
    t.boolean  "is_composite",                 default: false
    t.boolean  "is_negated",                   default: false
    t.boolean  "is_imported",                  default: false
    t.boolean  "is_reference",                 default: false
    t.integer  "old_parent_id"
    t.integer  "resp_entity_stix_ident_id"
    t.string   "stix_id"
    t.string   "dms_label"
    t.datetime "stix_timestamp"
    t.string   "title"
    t.datetime "updated_at"
    t.string   "downgrade_request_id"
    t.string   "created_by_user_guid"
    t.string   "updated_by_user_guid"
    t.string   "created_by_organization_guid"
    t.string   "updated_by_organization_guid"
    t.string   "guid"
    t.string   "legacy_color"
    t.string   "legacy_category"
    t.string   "received_from_system_guid"
    t.string   "reference"
    t.boolean  "public_release",               default: false
    t.integer  "old_acs_set_id"
    t.string   "alternative_id"
    t.boolean  "from_weather_map",             default: false
    t.string   "portion_marking"
    t.boolean  "read_only",                    default: false
    t.string   "title_c"
    t.string   "description_c"
    t.string   "indicator_type_c"
    t.string   "dms_label_c"
    t.string   "downgrade_request_id_c"
    t.string   "reference_c"
    t.string   "alternative_id_c"
    t.string   "timelines"
    t.string   "source_of_report"
    t.string   "target_of_attack"
    t.string   "target_scope"
    t.string   "actor_attribution"
    t.string   "actor_type"
    t.string   "modus_operandi"
    t.boolean  "is_ais",                       default: false
    t.string   "observable_type"
    t.text     "observable_value"
    t.text     "threat_actor_id"
    t.text     "threat_actor_title"
    t.datetime "start_time"
    t.string   "start_time_precision"
    t.datetime "end_time"
    t.string   "end_time_precision"
    t.boolean  "is_ciscp",                     default: false
    t.boolean  "is_mifr",                      default: false
    t.string   "feeds"
    t.string   "parent_id"
    t.string   "acs_set_id"
  end

  add_index "stix_indicators", ["from_weather_map"], name: "index_stix_indicators_on_from_weather_map"
  add_index "stix_indicators", ["guid"], name: "index_stix_indicators_on_guid"
  add_index "stix_indicators", ["stix_id"], name: "index_stix_indicators_on_stix_id"
  add_index "stix_indicators", ["updated_at"], name: "index_stix_indicators_on_updated_at"

  create_table "stix_indicators_packages", force: :cascade do |t|
    t.string   "stix_package_id"
    t.string   "stix_indicator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.boolean  "transfer_from_low", default: false
  end

  add_index "stix_indicators_packages", ["guid"], name: "index_stix_indicators_packages_on_guid"
  add_index "stix_indicators_packages", ["stix_indicator_id"], name: "index_stix_indicators_packages_on_stix_indicator_id"
  add_index "stix_indicators_packages", ["stix_package_id"], name: "index_stix_indicators_packages_on_stix_package_id"

  create_table "stix_kill_chain_phases", force: :cascade do |t|
    t.string   "guid",                                     null: false
    t.integer  "ordinality"
    t.string   "phase_name",                               null: false
    t.string   "stix_kill_chain_id",                       null: false
    t.string   "stix_kill_chain_phase_id",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",        default: false
  end

  add_index "stix_kill_chain_phases", ["stix_kill_chain_id"], name: "index_stix_kill_chain_phases_on_stix_kill_chain_id"
  add_index "stix_kill_chain_phases", ["stix_kill_chain_phase_id"], name: "index_stix_kill_chain_phases_on_stix_kill_chain_phase_id"

  create_table "stix_kill_chain_refs", force: :cascade do |t|
    t.string   "guid",                                     null: false
    t.string   "stix_kill_chain_id",                       null: false
    t.string   "stix_kill_chain_phase_id",                 null: false
    t.string   "remote_object_id",                         null: false
    t.string   "remote_object_type",                       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",        default: false
  end

  add_index "stix_kill_chain_refs", ["remote_object_id"], name: "index_stix_kill_chain_refs_on_remote_object_id"

  create_table "stix_kill_chains", force: :cascade do |t|
    t.string   "definer"
    t.string   "guid",                               null: false
    t.string   "kill_chain_name",                    null: false
    t.string   "reference"
    t.string   "stix_kill_chain_id",                 null: false
    t.boolean  "is_default",         default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",  default: false
  end

  add_index "stix_kill_chains", ["stix_kill_chain_id"], name: "index_stix_kill_chains_on_stix_kill_chain_id"

  create_table "stix_markings", force: :cascade do |t|
    t.boolean  "is_reference",               default: false, null: false
    t.string   "guid"
    t.string   "old_marking_model_name"
    t.string   "old_marking_model_type"
    t.string   "old_marking_name"
    t.text     "old_marking_value"
    t.string   "remote_object_id"
    t.string   "remote_object_type"
    t.string   "stix_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tlp_structure_id"
    t.string   "simple_structure_id"
    t.string   "isa_marking_structure_id"
    t.string   "isa_assertion_structure_id"
    t.string   "remote_object_field"
    t.text     "controlled_structure"
    t.boolean  "transfer_from_low",          default: false
  end

  add_index "stix_markings", ["remote_object_id"], name: "index_stix_markings_on_remote_object_id"
  add_index "stix_markings", ["stix_id"], name: "index_stix_markings_on_stix_id"
  add_index "stix_markings", ["updated_at"], name: "index_stix_markings_on_updated_at"

  create_table "stix_packages", force: :cascade do |t|
    t.datetime "created_at"
    t.text     "description"
    t.datetime "info_src_produced_time"
    t.boolean  "is_reference",                 default: false
    t.string   "package_intent",               default: "Indicators"
    t.text     "short_description"
    t.string   "stix_id"
    t.datetime "stix_timestamp"
    t.string   "title"
    t.datetime "updated_at"
    t.integer  "old_uploaded_file_id"
    t.string   "username"
    t.string   "created_by_user_guid"
    t.string   "updated_by_user_guid"
    t.string   "created_by_organization_guid"
    t.string   "updated_by_organization_guid"
    t.string   "r5_container_type"
    t.integer  "r5_container_id"
    t.string   "guid"
    t.string   "legacy_color"
    t.string   "legacy_category"
    t.integer  "old_acs_set_id"
    t.string   "submission_mechanism"
    t.string   "portion_marking"
    t.boolean  "read_only",                    default: false
    t.string   "title_c"
    t.string   "description_c"
    t.string   "short_description_c"
    t.string   "package_intent_c"
    t.string   "produced_time_precision"
    t.boolean  "is_ciscp",                     default: false
    t.string   "short_description_normalized"
    t.boolean  "is_mifr",                      default: false
    t.string   "feeds"
    t.string   "src_feed"
    t.string   "uploaded_file_id"
    t.string   "acs_set_id"
  end

  add_index "stix_packages", ["guid"], name: "index_stix_packages_on_guid"
  add_index "stix_packages", ["short_description_normalized"], name: "index_stix_packages_on_short_description_normalized"
  add_index "stix_packages", ["stix_id"], name: "index_stix_packages_on_stix_id"
  add_index "stix_packages", ["updated_at"], name: "index_stix_packages_on_updated_at"

  create_table "stix_related_objects", force: :cascade do |t|
    t.string   "remote_dest_object_type"
    t.string   "remote_dest_object_guid"
    t.string   "remote_src_object_type"
    t.string   "remote_src_object_guid"
    t.string   "stix_information_source_id"
    t.string   "relationship_type"
    t.string   "guid"
    t.string   "created_by_user_guid"
    t.string   "updated_by_user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",          default: false
  end

  create_table "stix_sightings", force: :cascade do |t|
    t.text     "description"
    t.datetime "sighted_at"
    t.string   "stix_indicator_id"
    t.string   "guid"
    t.string   "user_guid"
    t.string   "sighted_at_precision"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low",    default: false
  end

  add_index "stix_sightings", ["guid"], name: "index_stix_sightings_on_guid"
  add_index "stix_sightings", ["stix_indicator_id"], name: "index_stix_sightings_on_stix_indicator_id"

  create_table "system_logs", force: :cascade do |t|
    t.string   "stix_package_id",      null: false
    t.string   "sanitized_package_id"
    t.datetime "timestamp",            null: false
    t.string   "source",               null: false
    t.string   "log_level",            null: false
    t.string   "message",              null: false
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tag_assignments", force: :cascade do |t|
    t.datetime "created_at",                         null: false
    t.string   "remote_object_guid",                 null: false
    t.string   "remote_object_type",                 null: false
    t.string   "justification"
    t.integer  "tag_id"
    t.string   "tag_guid",                           null: false
    t.string   "user_guid"
    t.string   "guid"
    t.string   "tag_type"
    t.boolean  "transfer_from_low",  default: false
  end

  add_index "tag_assignments", ["guid"], name: "index_tag_assignments_on_guid"

  create_table "tags", force: :cascade do |t|
    t.string   "name",                              null: false
    t.string   "name_normalized",                   null: false
    t.string   "user_guid"
    t.integer  "r5_collection_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.boolean  "is_permanent",      default: false
    t.boolean  "transfer_from_low", default: false
  end

  add_index "tags", ["guid"], name: "index_tags_on_guid"

  create_table "threat_actors", force: :cascade do |t|
    t.string   "title"
    t.string   "title_c"
    t.text     "description"
    t.string   "description_c"
    t.text     "short_description"
    t.string   "short_description_c"
    t.string   "identity_name"
    t.string   "identity_name_c"
    t.string   "stix_id"
    t.string   "portion_marking"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "created_by_user_guid"
    t.string   "updated_by_user_guid"
    t.string   "created_by_organization_guid"
    t.string   "updated_by_organization_guid"
    t.integer  "old_acs_set_id"
    t.boolean  "read_only",                    default: false
    t.boolean  "is_mifr",                      default: false
    t.boolean  "is_ciscp",                     default: false
    t.string   "feeds"
    t.string   "acs_set_id"
  end

  add_index "threat_actors", ["guid"], name: "index_threat_actors_on_guid"
  add_index "threat_actors", ["stix_id"], name: "index_threat_actors_on_stix_id"
  add_index "threat_actors", ["updated_at"], name: "index_threat_actors_on_updated_at"

  create_table "tlp_structures", force: :cascade do |t|
    t.string   "color",                             null: false
    t.string   "guid",                              null: false
    t.string   "stix_id",                           null: false
    t.string   "stix_marking_id"
    t.datetime "updated_at"
    t.boolean  "transfer_from_low", default: false
  end

  create_table "ttp_attack_patterns", force: :cascade do |t|
    t.string   "stix_ttp_id"
    t.string   "stix_attack_pattern_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "user_guid"
    t.boolean  "transfer_from_low",      default: false
  end

  add_index "ttp_attack_patterns", ["guid"], name: "index_ttp_attack_patterns_on_guid"
  add_index "ttp_attack_patterns", ["stix_attack_pattern_id"], name: "index_ttp_attack_patterns_on_stix_attack_pattern_id"
  add_index "ttp_attack_patterns", ["stix_ttp_id"], name: "index_ttp_attack_patterns_on_stix_ttp_id"

  create_table "ttp_exploit_targets", force: :cascade do |t|
    t.string   "stix_ttp_id"
    t.string   "stix_exploit_target_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "user_guid"
    t.boolean  "transfer_from_low",      default: false
  end

  add_index "ttp_exploit_targets", ["guid"], name: "index_ttp_exploit_targets_on_guid"
  add_index "ttp_exploit_targets", ["stix_exploit_target_id"], name: "index_ttp_exploit_targets_on_stix_exploit_target_id"
  add_index "ttp_exploit_targets", ["stix_ttp_id"], name: "index_ttp_exploit_targets_on_stix_ttp_id"

  create_table "ttp_packages", force: :cascade do |t|
    t.string   "stix_ttp_id"
    t.string   "stix_package_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "user_guid"
    t.boolean  "transfer_from_low", default: false
  end

  add_index "ttp_packages", ["guid"], name: "index_ttp_packages_on_guid"
  add_index "ttp_packages", ["stix_package_id"], name: "index_ttp_packages_on_stix_package_id"
  add_index "ttp_packages", ["stix_ttp_id"], name: "index_ttp_packages_on_stix_ttp_id"

  create_table "ttps", force: :cascade do |t|
    t.string   "stix_id"
    t.string   "portion_marking"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "created_by_user_guid"
    t.string   "updated_by_user_guid"
    t.string   "created_by_organization_guid"
    t.string   "updated_by_organization_guid"
    t.integer  "old_acs_set_id"
    t.datetime "stix_timestamp"
    t.boolean  "read_only",                    default: false
    t.boolean  "is_ciscp",                     default: false
    t.boolean  "is_mifr",                      default: false
    t.string   "feeds"
    t.string   "acs_set_id"
  end

  add_index "ttps", ["guid"], name: "index_ttps_on_guid"
  add_index "ttps", ["stix_id"], name: "index_ttps_on_stix_id"
  add_index "ttps", ["updated_at"], name: "index_ttps_on_updated_at"

  create_table "uploaded_files", force: :cascade do |t|
    t.boolean  "is_attachment",                 default: false, null: false
    t.string   "file_name",                                     null: false
    t.integer  "file_size"
    t.string   "status",              limit: 1, default: "N",   null: false
    t.boolean  "validate_only",                 default: false, null: false
    t.string   "user_guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.boolean  "overwrite",                     default: false, null: false
    t.boolean  "human_review_needed",           default: false
    t.boolean  "read_only",                     default: false
    t.string   "portion_marking"
    t.string   "reference_title"
    t.string   "reference_number"
    t.string   "reference_link"
    t.boolean  "avp_validation"
    t.boolean  "avp_fail_continue"
    t.boolean  "avp_valid"
    t.string   "avp_message_id"
    t.string   "src_feed"
    t.string   "zip_status"
    t.boolean  "final",                         default: false
  end

  add_index "uploaded_files", ["guid"], name: "index_uploaded_files_on_guid"
  add_index "uploaded_files", ["updated_at"], name: "index_uploaded_files_on_updated_at"
  add_index "uploaded_files", ["user_guid"], name: "index_uploaded_files_on_user_guid"

  create_table "user_sessions", force: :cascade do |t|
    t.string   "username"
    t.string   "session_id"
    t.datetime "session_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "username"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "password_hash"
    t.string   "password_salt"
    t.string   "organization_guid"
    t.datetime "locked_at"
    t.datetime "logged_in_at"
    t.integer  "failed_login_attempts",    default: 0
    t.datetime "expired_at"
    t.datetime "disabled_at"
    t.boolean  "password_change_required", default: false
    t.datetime "password_changed_at"
    t.datetime "terms_accepted_at"
    t.datetime "hidden_at"
    t.integer  "throttle",                 default: 0
    t.boolean  "machine",                  default: false
    t.integer  "r5_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_key"
    t.string   "api_key_secret_encrypted"
    t.string   "guid"
    t.string   "notes"
    t.string   "remote_guid"
    t.boolean  "transfer_from_low",        default: false
  end

  add_index "users", ["guid"], name: "index_users_on_guid"

  create_table "users_groups", force: :cascade do |t|
    t.integer  "group_id"
    t.string   "user_guid"
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.string   "guid"
  end

  add_index "users_groups", ["guid"], name: "index_users_groups_on_guid"

  create_table "vulnerabilities", force: :cascade do |t|
    t.string   "title"
    t.string   "title_c"
    t.text     "description"
    t.string   "description_c"
    t.string   "cve_id"
    t.string   "cve_id_c"
    t.string   "osvdb_id"
    t.string   "osvdb_id_c"
    t.string   "portion_marking"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.string   "created_by_user_guid"
    t.string   "updated_by_user_guid"
    t.string   "created_by_organization_guid"
    t.string   "updated_by_organization_guid"
    t.datetime "stix_timestamp"
    t.boolean  "read_only",                    default: false
    t.string   "description_normalized"
    t.boolean  "is_mifr",                      default: false
    t.boolean  "is_ciscp",                     default: false
    t.string   "feeds"
  end

  add_index "vulnerabilities", ["guid"], name: "index_vulnerabilities_on_guid"
  add_index "vulnerabilities", ["updated_at"], name: "index_vulnerabilities_on_updated_at"

  create_table "weather_map_images", force: :cascade do |t|
    t.string   "organization_token"
    t.integer  "image_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "weather_map_images", ["image_id"], name: "index_weather_map_images_on_image_id"

end
