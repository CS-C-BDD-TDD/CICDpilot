require 'test_helper'

class UploadedFileTest < ActiveSupport::TestCase
  def setup
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    @ciap_id_mapping1 = CiapIdMapping.create!(
      before_id: 'test_uid1',
      after_id: 'NCCIC:uid1'
    )
    
    @ciap_id_mapping2 = CiapIdMapping.create!(
      before_id: 'test_uid2',
      after_id: 'NCCIC:uid2'
    )
    
    @orig_input1 = OriginalInput.create!(
      mime_type: 'text/plain',
      raw_content: File.read('test/fixtures/files/package_no_confidence.xml'),
      remote_object_id: 'NCCIC:TestName-0123456789',
      remote_object_type: 'StixPackage',
      uploaded_file_id: 1,
      guid: '0123456789',
      input_category: 'Upload',
      input_sub_category: 'Transmit',
      ciap_id_mappings: [@ciap_id_mapping1, @ciap_id_mapping2]
    )

    @upload1 = UploadedFile.create!(
      is_attachment: false,
      file_name: 'TestFileName',
      file_size: 10,
      status: 'S',
      validate_only: false,
      user_guid: 'TestUserGuid',
      guid: 'TestGuid',
      overwrite: false,
      human_review_needed: true,
      zip_file_id: 5,
      read_only: false,
      portion_marking: 'TestPortionMarking',
      reference_title: 'TestReferenceTitle',
      reference_number: 'TestReferenceNumber',
      reference_link: 'TestReferenceLink',
      avp_validation: false,
      avp_fail_continue: false,
      avp_valid: false,
      avp_message_id: 'TestAvpMessageId',
      original_inputs: [@orig_input1]
    )
    
    setup_api_user
    @indicator1 = Indicator.create!(stix_id: "NCCIC:Indicator-6bb61900-2258-11e4-8c21-0800200cba66",
        title:"A",description:"B",indicator_type:"Benign")
  end
  
  def teardown
    ::Sunspot.session = ::Sunspot.session.original_session
  end
  
  test "json serialization includes id mappings" do
    js = @upload1.as_json
    assert_not_empty(js)
    
    # Verify fields that should be there actually are
    assert_not_empty(js['original_inputs'])
    inputs = js['original_inputs']
    assert_equal(1, inputs.length)
    assert_not_empty(inputs[0]['ciap_id_mappings'])
    mappings = inputs[0]['ciap_id_mappings']
    assert_equal(2, mappings.length)
    
    assert_equal('NCCIC:uid1', mappings[0]['sanitized_id'])
    assert_equal('NCCIC:uid2', mappings[1]['sanitized_id'])
  end
  
  test "update_confidences does nothing when no confidences are available" do
    orig_xml = String.new(@upload1.original_inputs.first.raw_content)
    
    pkg = StixPackage.create
    @upload1.stix_packages << pkg
    
    @upload1.send(:update_confidences, pkg)
    
    assert_equal orig_xml, @upload1.original_inputs.first.raw_content
  end
  
  test "update_confidences removes existing confidence from xml" do
    oi = @upload1.original_inputs.first
    
    conf_xml = File.read('test/fixtures/files/package_includes_confidence.xml')
    
    oi.raw_content = conf_xml
    oi.save

    pkg = StixPackage.create
    @upload1.stix_packages << pkg

    @upload1.send(:update_confidences, pkg)
    @upload1.reload

    assert_no_match(/Confidence/, @upload1.original_inputs.first.raw_content)    
  end
  
  test "update_confidences adds confidence to xml" do
    u1 = Uri.create(uri_input:'http://www.cnn.com/')
    o1 = Observable.create(object: u1, indicator: @indicator1)
    u1.observables = [o1]

    c1 = Confidence.create(remote_object_type: 'Indicator', remote_object_id: @indicator1.id, 
        value: 'medium', is_official: true, indicator: @indicator1)
    @indicator1.confidences << c1
    
    pkg = StixPackage.create
    pkg.indicators << @indicator1
    
    @upload1.stix_packages << pkg
    @upload1.send(:update_confidences, pkg)
    @upload1.reload
    
    assert_match(/Confidence/, @upload1.original_inputs.first.raw_content)    
  end
  
  test "update_sightings does nothing when no sightings are available" do
    orig_xml = String.new(@upload1.original_inputs.first.raw_content)
    
    pkg = StixPackage.create
    @upload1.stix_packages << pkg
    
    @upload1.send(:update_sightings, pkg)
    
    assert_equal orig_xml, @upload1.original_inputs.first.raw_content
  end
  
  test "update_sightings updates existing sighting" do
    oi = @upload1.original_inputs.first
    
    conf_xml = File.read('test/fixtures/files/package_includes_sighting.xml')
    
    oi.raw_content = conf_xml
    oi.save

    @indicator1.stix_id = "NCCIC:ind-04-2"
    @indicator1.save
    pkg = StixPackage.create!(title: 'A Title', indicators: [@indicator1])
    @upload1.stix_packages << pkg

    @upload1.send(:update_sightings, pkg)
    @upload1.reload

    xml = Nokogiri::XML(@upload1.original_inputs.first.raw_content)
    xpath_exp="//*[local-name()='Sighting']"
    sight_nodes = xml.search(xpath_exp)
    assert_equal 2, sight_nodes.size
    
    xpath_exp="//*[local-name()='Sightings']"
    top_nodes = xml.search(xpath_exp)
    assert_equal '0', top_nodes.first['sightings_count']
  end
  
  test "update_sightings adds sightings to xml" do
    oi = @upload1.original_inputs.first
    conf_xml = File.read('test/fixtures/files/package_no_confidence.xml')
    
    oi.raw_content = conf_xml
    oi.save
    
    u1 = Uri.create(uri_input:'http://www.cnn.com/')
    o1 = Observable.create(object: u1, indicator: @indicator1)
    u1.observables = [o1]

    sight1 = Sighting.create!(sighted_at: Time.now, description: 'A Desc')
    sight2 = Sighting.create!(sighted_at: Time.now, description: 'B Desc')
    @indicator1.sightings << sight1
    @indicator1.sightings << sight2
    
    pkg = StixPackage.create!(title: 'A Title', indicators: [@indicator1])
    
    @upload1.stix_packages << pkg
    @upload1.send(:update_sightings, pkg)
    @upload1.reload
    
    xml = Nokogiri::XML(@upload1.original_inputs.first.raw_content)
    xpath_exp="//*[local-name()='Sightings']"
    top_nodes = xml.search(xpath_exp)
    assert_equal '2', top_nodes.first['sightings_count']
  end
end
