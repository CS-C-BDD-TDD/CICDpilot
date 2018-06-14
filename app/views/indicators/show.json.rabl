object @indicator

attributes :id,
           :composite_operator,
           :description,
           :indicator_type,
           :reference,
           :indicator_type_vocab_name,
           :indicator_type_vocab_ref,
           :is_composite,
           :is_negated,
           :is_reference,
           :parent_id,
           :resp_entity_stix_ident_id,
           :stix_id,
           :dms_label,
           :stix_timestamp,
           :title,
           :created_at,
           :updated_at,
           :guid,
           :downgrade_request_id,
           :color,
           :alternative_id,
           :from_weather_map,
           :acs_set_id,
           :portion_marking,
           :read_only,
           :title_c,
           :description_c,
           :indicator_type_c,
           :dms_label_c,
           :downgrade_request_id_c,
           :reference_c,
           :alternative_id_c,
           :timelines,
           :source_of_report,
           :target_of_attack,
           :target_scope,
           :actor_attribution,
           :actor_type,
           :modus_operandi,
           :observable_type,
           :observable_value,
           :threat_actor_id,
           :threat_actor_title,
           :is_ais,
           :is_ciscp,
           :is_mifr,
		   :feeds

child :confidences => 'confidences' do
  extends "confidences/index", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:confidences] == 'embedded') && locals[:associations][:confidences] == 'none'

node :confidences do |indicator|
  confidence = indicator.confidences.first
  [{value: confidence.value}]
end unless locals['indicator'] || locals[:associations][:confidences] == 'embedded'|| locals[:associations][:confidences] == 'none' || locals[:object].confidences.blank? || !locals[:object].confidences.first.is_official

child :observables => 'observables' do
  extends "observables/index", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:observables]) && locals[:associations][:observables] == 'none'

child :kill_chain_phases => 'kill_chain_phases' do
  extends "kill_chain_phases/index", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:kill_chain_phases]) && locals[:associations][:observables] != 'none'

child :sightings => 'sightings' do
  extends "sightings/index", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:sightings]) && locals[:associations][:sightings] != 'none'

if User.has_permission(current_user,'tag_item_with_user_tag')
  node :user_tags do |indicator|
    user_tags = indicator.user_tags
    user_tags = user_tags.where(user_guid:current_user.guid)
    partial("user_tags/index", object: user_tags, locals: {associations: locals[:associations]})
  end if (locals['indicator'] || locals[:associations][:user_tags]) && locals[:associations][:user_tags] != 'none'
end

child :threat_actors => 'threat_actors' do |tags|
  extends "threat_actors/index", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:threat_actors]) && locals[:associations][:threat_actors] != 'none'

child :course_of_actions => 'course_of_actions' do |tags|
  extends "course_of_actions/index", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:course_of_actions]) && locals[:associations][:course_of_actions] != 'none'

child :ttps => 'ttps' do |ttps|
  extends "ttps/index", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:ttps]) && locals[:associations][:ttps] != 'none'

child :audits => 'audits' do
  extends "audits/index", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:audits]) && locals[:associations][:audits] != 'none'

if User.has_permission(current_user,'view_analyst_notes')
  child :notes => 'notes' do
    extends "notes/index", locals: {associations: locals[:associations]}
  end if (locals['indicator'] || locals[:associations][:notes]) && locals[:associations][:notes] != 'none'
end

child created_by_user: 'created_by_user' do
  extends "users/show", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:created_by_user]) && locals[:associations][:created_by_user] != 'none'

child :exported_indicators do
  extends "exported_indicators/index", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:exported_indicators]) && locals[:associations][:exported_indicators] != 'none'

node :related_indicators do |indicator|
    related_indicators = indicator.related_to_objects.collect do |r|
    {
        guid: r.guid,
        confidences: partial("confidences/index.json.rabl",object: r.confidences),
        relationship_type: r.relationship_type,
        stix_information_source_id: r.stix_information_source_id,
        created_at: r.created_at,
        updated_at: r.updated_at,
        indicator: partial("indicators/show.json.rabl",object: r.remote_dest_object)
    }
  end

  related_indicators += indicator.related_by_objects.collect do |r|
    {
        guid: r.guid,
        confidences: partial("confidences/index.json.rabl",object: r.confidences),
        relationship_type: r.relationship_type,
        stix_information_source_id: r.stix_information_source_id,
        created_at: r.created_at,
        updated_at: r.updated_at,
        indicator: partial("indicators/show.json.rabl",object: r.remote_src_object)
    }
  end
  related_indicators
end if (locals['indicator'] || locals[:associations][:related_indicators]) && locals[:associations][:related_indicators] != 'none'

node :stix_markings do |indicator|
  stix_markings = indicator.stix_markings.to_a
  stix_markings += indicator.acs_set.stix_markings if indicator.acs_set.present?
  partial 'stix_markings/index.json.rabl', object: stix_markings
end if (locals['indicator'] || locals[:associations][:stix_markings]) && locals[:associations][:stix_markings] != 'none'

child :stix_packages => 'stix_packages' do
  extends "stix_packages/index.json.rabl", locals: {associations: locals[:associations]}
end if (locals['indicator'] || locals[:associations][:stix_packages]) && locals[:associations][:stix_packages] != 'none'

node :acs_set do |indicator|
  acs_set = indicator.acs_set
  {name: acs_set.name,id: acs_set.id, portion_marking: acs_set.portion_marking} if acs_set.present?
end

node :attachments do |indicator|
  attachments = indicator.attachments.collect do |a|
  {
    id: a.uploaded_file.id,
    file_name: a.uploaded_file.file_name,
    username: User.find_by_guid(a.uploaded_file.user_guid).username,
    created_at: a.created_at,
    ref_title: a.uploaded_file.reference_title,
    ref_num: a.uploaded_file.reference_number,
    ref_link: a.uploaded_file.reference_link
  }
  end
  attachments
end if (locals['indicator'] || locals[:associations][:attachments]) && locals[:associations][:attachments] != 'none'
