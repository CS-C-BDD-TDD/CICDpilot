object @isa_assertion_structure

attributes  :id,
            :cs_classification,
            :cs_countries,
            :cs_cui,
            :cs_entity,
            :cs_formal_determination,
            :cs_info_caveat,
            :cs_orgs,
            :cs_shargrp,
            :guid,
            :is_default_marking,
            :is_reference,
            :privilege_default,
            :public_release,
            :public_released_by,
            :public_released_on,
            :stix_id,
            :stix_marking_guid,
            :created_at,
            :updated_at,
            :classified_by,
            :classified_on,
            :classification_reason

child :isa_privs => 'isa_privs' do
  attributes :action,:effect,:id
end

child :further_sharings => 'further_sharings' do
  attributes :scope, :effect, :id
end