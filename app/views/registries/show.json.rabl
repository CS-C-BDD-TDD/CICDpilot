object @registry

attributes :cybox_object_id,
           :hive,
           :hive_condition,
           :key,
           :created_at,
           :updated_at,
           :guid,
           :portion_marking,
           :read_only,
           :hive_c,
           :key_c,
           :is_ciscp,
           :is_mifr,
		   :feeds

if @registry || (root_object && root_object != :registry)
  registry_to_use = @registry
  if root_object
    registry_to_use = root_object
  end

  registry_to_use.registry_values.collect do |value|
    if (locals['registry'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'
      node do |dummy|
        if value.reg_name.present? && value.reg_value.present?
          {
           :reg_value_id => value.id,
           :reg_name => value.reg_name,
           :data_condition => value.data_condition,
           :reg_value => value.reg_value,
           :reg_name_c => value.reg_name_c,
           :reg_value_c => value.reg_value_c,
           ("reg_stix_markings").to_sym => (partial 'stix_markings/index.json.rabl', object: value.stix_markings)
         }
        elsif value.reg_name.present?
          {
           :reg_value_id => value.id,
           :reg_name => value.reg_name,
           :data_condition => value.data_condition,
           :reg_name_c => value.reg_name_c,
           ("reg_stix_markings").to_sym => (partial 'stix_markings/index.json.rabl', object: value.stix_markings)
          }
        elsif value.reg_value.present?
          {
           :reg_value_id => value.id,
           :reg_value => value.reg_value,
           :reg_value_c => value.reg_value_c,
           ("reg_stix_markings").to_sym => (partial 'stix_markings/index.json.rabl', object: value.stix_markings)
          }
        end
      end
    else
      node do |dummy|
        if value.reg_name.present? && value.reg_value.present?
          {
           :reg_value_id => value.id,
           :reg_name => value.reg_name,
           :reg_value => value.reg_value,
           :reg_name_c => value.reg_name_c,
           :reg_value_c => value.reg_value_c
         }
        elsif value.reg_name.present?
          {
           :reg_value_id => value.id,
           :reg_name => value.reg_name,
           :reg_name_c => value.reg_name_c
          }
        elsif value.reg_value.present?
          {
           :reg_value_id => value.id,
           :reg_value => value.reg_value,
           :reg_value_c => value.reg_value_c
          }
        end
      end
    end
  end
end

child :indicators => 'indicators' do
  extends "indicators/index.json.rabl", locals: {associations: locals[:associations].merge({confidences: 'embedded',observable: 'embedded'})}
end if (locals['registry'] || locals[:associations][:indicators]) && locals[:associations][:indicators] != 'none'

child :course_of_actions => 'course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['registry'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ind_course_of_actions => 'ind_course_of_actions' do
  extends "course_of_actions/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['registry'] || locals[:associations][:ind_course_of_actions]) && locals[:associations][:ind_course_of_actions] != 'none'

node :stix_markings do |registry|
  stix_markings = registry.stix_markings.to_a
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['registry'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['registry'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'
