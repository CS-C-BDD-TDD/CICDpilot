require 'test_helper'

class DnsRecordTest < ActiveSupport::TestCase
  def setup
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    setup_api_user
    @indicator1 = Indicator.create(title:"A",description:"B",indicator_type:"Benign")
    @record1 = DnsRecord.create!(address_input:'1.2.3.4',address_class:'IN',domain_input:'a',entry_type:'A')
    @observable1 = Observable.create(indicator: @indicator1, object: @record1)
  end
  
  def teardown
    @observable1 = nil
    @indicator1 = nil
    @record1 = nil
    ::Sunspot.session = ::Sunspot.session.original_session
  end

  test "get list of indicators" do
    @record1.reload
    assert @record1.indicators == [@indicator1]
  end

  test "get list of observables" do
    assert @record1.observables == [@observable1]
  end
  
  test "total_sightings returns 0 with no sightings" do
    @record1.reload
    
    # No sightings
    assert_equal 0, @record1.total_sightings
    
    # No indicator
    record2 = DnsRecord.create(address_input:'10.20.30.40',address_class:'IN',domain_input:'a',entry_type:'A')
    observable2 = Observable.create(object: record2)
    record2.reload
    assert_equal 0, record2.total_sightings
    
    # No observable
    record3 = DnsRecord.create(address_input:'11.21.31.41',address_class:'IN',domain_input:'a',entry_type:'A')
    assert_equal 0, record3.total_sightings
  end
  
  test "total_sightings returns count from one indicator" do
    @record1.reload
    
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting')
    @indicator1.sightings << sight1
    
    assert_equal 1, @record1.total_sightings
  end
  
  test "total_sightings returns count from multiple indicators" do
    @record1.reload
    
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 1')
    sight2 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 2')
    @indicator1.sightings << sight1
    @indicator1.sightings << sight2
    
    indicator2 = Indicator.create(title:"A2",description:"B2",indicator_type:"Benign")
    observable2 = Observable.create(indicator: indicator2, object: @record1)
    
    sight3 = Sighting.create(sighted_at: Time.now, description: 'Test Soghting 2')
    indicator2.sightings << sight3
    
    assert_equal 3, @record1.total_sightings
  end
end
