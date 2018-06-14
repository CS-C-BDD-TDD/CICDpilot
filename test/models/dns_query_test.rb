require 'test_helper'

class DnsQueryTest < ActiveSupport::TestCase
  def setup
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    setup_api_user
    @indicator1 = Indicator.create(title:"A",description:"B",indicator_type:"Benign")
    @query1 = DnsQuery.create
    @observable1 = Observable.create(indicator: @indicator1, object: @query1)
  end
  
  def teardown
    @observable1 = nil
    @indicator1 = nil
    @query1 = nil
    ::Sunspot.session = ::Sunspot.session.original_session
  end

  test "total_sightings returns 0 with no sightings" do
    # No sightings
    assert_equal 0, @query1.total_sightings
    
    # No indicator
    query2 = DnsQuery.create
    observable2 = Observable.create(object: query2)
    assert_equal 0, query2.total_sightings
    
    # No observable
    query3 = DnsQuery.create
    assert_equal 0, query3.total_sightings
  end
  
  test "total_sightings returns count from one indicator" do
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting')
    @indicator1.sightings << sight1
    
    assert_equal 1, @query1.total_sightings
  end
  
  test "total_sightings returns count from multiple indicators" do
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 1')
    sight2 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 2')
    @indicator1.sightings << sight1
    @indicator1.sightings << sight2
    
    indicator2 = Indicator.create(title:"A2",description:"B2",indicator_type:"Benign")
    observable2 = Observable.create(indicator: indicator2, object: @query1)
    
    sight3 = Sighting.create(sighted_at: Time.now, description: 'Test Soghting 2')
    indicator2.sightings << sight3
    
    assert_equal 3, @query1.total_sightings
  end
end
