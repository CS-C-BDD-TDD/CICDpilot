require 'test_helper'

class ObservableTest < ActiveSupport::TestCase
  def setup
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    setup_api_user
    @indicator1 = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
  end
  
  def teardown
    ::Sunspot.session = ::Sunspot.session.original_session
  end

  test "get indicator" do
    d1 = Domain.create!(name_input:'a',name_condition:'Equals')
    o1 = Observable.create!(indicator: @indicator1, object: d1)
    assert o1.indicator == @indicator1
  end

  test "get domain" do
    d1 = Domain.create!(name_input:'a',name_condition:'Equals')
    o1 = Observable.create!(indicator: @indicator1, object: d1)
    assert o1.domain == d1
  end

  test "get address" do
    a1 = Address.create!(address_input:'1.2.3.4')
    o1 = Observable.create!(indicator: @indicator1, object: a1)
    assert o1.address == a1
  end

  test "get uri" do
    u1 = Uri.create!(uri_input:'http://www.cnn.com')
    o1 = Observable.create!(indicator: @indicator1, object: u1)
    assert o1.uri == u1
  end

  test "get email" do
    e1 = EmailMessage.create!(subject:'a')
    o1 = Observable.create!(indicator: @indicator1, object: e1)
    assert o1.email_message == e1
  end

  test "get dns record" do
    d1 = DnsRecord.create!(address_input:'1.2.3.4',address_class:'IN',domain_input:'a',entry_type:'A')
    o1 = Observable.create!(indicator: @indicator1, object: d1)
    assert o1.dns_record == d1
  end
  
  test "latest_confidence with no object returns nil" do
    o1 = Observable.create(indicator: @indicator1, object: nil)
    assert_nil o1.latest_confidence    
  end
  
  test "latest_confidence with object containing an indicator with no confidence returns nil" do
    u1 = Uri.create(uri_input:'http://www.cnn.com')
    o1 = Observable.create(indicator: @indicator1, object: u1)
    assert_nil o1.latest_confidence
  end
  
  test "latest_confidence with only a non-official confidence returns nil" do
    c1 = Confidence.create(remote_object_type: 'Indicator', remote_object_id: @indicator1.id, 
        value: 'medium', is_official: false, indicator: @indicator1)
    @indicator1.confidences << c1
    
    u1 = Uri.create(uri_input:'http://www.cnn.com')
    o1 = Observable.create(indicator: @indicator1, object: u1)
    assert_nil o1.latest_confidence
  end

  test "latest_confidence with only a official confidence returns confidence" do
    c1 = Confidence.create(remote_object_type: 'Indicator', remote_object_id: @indicator1.id, 
        value: 'medium', is_official: true, indicator: @indicator1)
    @indicator1.confidences << c1
    
    u1 = Uri.create(uri_input:'http://www.cnn.com')
    o1 = Observable.create(indicator: @indicator1, object: u1)
    
    ret_conf = o1.latest_confidence
    assert_not_nil ret_conf
    assert_equal c1, ret_conf
  end

  test "latest_confidence with one official, one non-official returns official" do
    c1 = Confidence.create(remote_object_type: 'Indicator', remote_object_id: @indicator1.id, 
        value: 'medium', is_official: true, indicator: @indicator1)
    @indicator1.confidences << c1
    
    i2 = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    c2 = Confidence.create(remote_object_type: 'Indicator', remote_object_id: @indicator1.id, 
        value: 'medium', is_official: false, indicator: @indicator1)
    i2.confidences << c2

    u1 = Uri.create(uri_input:'http://www.cnn.com')
    o1 = Observable.create(indicator: @indicator1, object: u1)
    o2 = Observable.create(indicator: i2, object: u1)
    
    ret_conf = o1.latest_confidence
    assert_not_nil ret_conf
    assert_equal c1, ret_conf
  end

  test "latest_confidence with two official returns latest" do
    c1 = Confidence.create(remote_object_type: 'Indicator', remote_object_id: @indicator1.id, 
        value: 'medium', is_official: true, indicator: @indicator1)
    @indicator1.confidences << c1
    
    i2 = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    c2 = Confidence.create(remote_object_type: 'Indicator', remote_object_id: @indicator1.id, 
        value: 'medium', is_official: true, indicator: @indicator1)
    i2.confidences << c2

    u1 = Uri.create(uri_input:'http://www.cnn.com')
    o1 = Observable.create(indicator: @indicator1, object: u1)
    o2 = Observable.create(indicator: i2, object: u1)
    
    ret_conf = o1.latest_confidence
    assert_not_nil ret_conf
    assert_equal c2, ret_conf
  end
  
  test "total_sightings returns 0 with no sightings" do
    u1 = Uri.create(uri_input:'http://www.cnn.com')
    o1 = Observable.create(indicator: @indicator1, object: u1)
    
    # No sightings
    assert_equal 0, o1.total_sightings
    
    # No indicator
    u2 = Uri.create(uri_input:'http://www.cnn-2.com')
    o2 = Observable.create!(object: u2)
    assert_equal 0, o2.total_sightings
  end
  
  test "total_sightings returns count from one indicator" do
    u1 = Uri.create(uri_input:'http://www.cnn.com')
    o1 = Observable.create(indicator: @indicator1, object: u1)
    
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting')
    @indicator1.sightings << sight1
    
    assert_equal 1, o1.total_sightings
  end
  
  test "total_sightings returns count from multiple indicators" do
    u1 = Uri.create(uri_input:'http://www.cnn.com')
    o1 = Observable.create(indicator: @indicator1, object: u1)

    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 1')
    sight2 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 2')
    @indicator1.sightings << sight1
    @indicator1.sightings << sight2
    
    indicator2 = Indicator.create(title:"A2",description:"B2",indicator_type:"Benign")
    o2 = Observable.create(indicator: indicator2, object: u1)
    
    sight3 = Sighting.create(sighted_at: Time.now, description: 'Test Soghting 2')
    indicator2.sightings << sight3
    
    assert_equal 3, o2.total_sightings
  end
end
