Instructions for Migrating CIAP v5 to CIAP v6
=================================================

## Pre-Migration Tasks

Export all tables to backup files

Execute this command for ever table in the database:

exp username/password@db table=table_name file=table_name.dmp

Use your username and password for access to the db, and db is the name of the database CIAP uses.
Replace table_name with the of the table from the following list.

List of tables to export to file are:

searches
uploaded_files
collection_elements
organizations
settings
old_phrases
old_hosts
old_emails
old_philes
old_whois
old_elements
old_ports
delayed_jobs
old_phrases2
network_activities
old_whois_domain
old_whois_ipv4
error_messages
impacted_orgs
old_ipv6s
old_whois_ipv6
old_metrics
impressions
old_audits
old_elements2
workspaces
collections
old_dns_resolutions
old_domains
old_email_addresses
old_email_subjects
old_emails2
old_ipv4s
old_md5_hashes
old_philes2
old_sha1_hashes
old_sha256_hashes
sightings
parcels
parcel_sightings
sighting_transfers
e2_signatures
e2_alert_statistics
e2_subdomains
task_types
task_histories
domain_info
email_elements
email_address_info
ipv4_info
ipv6_elements
ipv6_info
phile_elements
sha256_info
sha1_info
md5_info
phrase_elements
phrase_info
pdf_details
section_hashes
yara_rules
details
audits
old_uris
relationships
users
gfi_uploads
domain_ele_class_raw_audits
domain_ele_class_audits
domain_info_class_audits
email_ele_class_raw_audits
email_ele_class_audits
email_add_info_class_audits
ipv4_ele_class_raw_audits
ipv4_ele_class_audits
ipv4_info_class_audits
ipv6_ele_class_raw_audits
ipv6_ele_class_audits
ipv6_info_class_audits
phile_ele_class_raw_audits
phile_ele_class_audits
md5_info_class_audits
sha1_info_class_audits
sha256_info_class_audits
phrase_ele_class_raw_audits
details
audits
old_uris
relationships
users
gfi_uploads
domain_ele_class_raw_audits
domain_ele_class_audits
domain_info_class_audits
email_ele_class_raw_audits
email_ele_class_audits
email_add_info_class_audits
ipv4_ele_class_raw_audits
ipv4_ele_class_audits
ipv4_info_class_audits
ipv6_ele_class_raw_audits
ipv6_ele_class_audits
ipv6_info_class_audits
phile_ele_class_raw_audits
phile_ele_class_audits
md5_info_class_audits
sha1_info_class_audits
sha256_info_class_audits
phrase_ele_class_raw_audits
phrase_ele_class_audits
phrase_info_class_audits
col_class_raw_audits
sighting_class_raw_audits
exported_indicators
domain_elements
ipv4_elements
dns_resolution_elements
uri_info
uri_info_class_audits
uri_elements
uri_ele_class_raw_audits
uri_ele_class_audits
attribute_histories
collection_transfers
stix_reports
report_organizations
collection_imports
attachments
