require 'test_helper'

class HttpSessionTest < ActiveSupport::TestCase
  def setup
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    setup_api_user
    @indicator1 = Indicator.create(title:"A",description:"B",indicator_type:"Benign")
    @session1 = HttpSession.create!(user_agent:'Mozilla 34.0')
    @observable1 = Observable.create(indicator: @indicator1, object: @session1)
  end
  
  def teardown
    @observable1 = nil
    @indicator1 = nil
    @session1 = nil
    ::Sunspot.session = ::Sunspot.session.original_session
  end

  test "get list of indicators" do
    @session1.reload
    assert @session1.indicators == [@indicator1]
  end

  test "get list of observables" do
    assert @session1.observables == [@observable1]
  end
  
  test "total_sightings returns 0 with no sightings" do
    @session1.reload
    
    # No sightings
    assert_equal 0, @session1.total_sightings
    
    # No indicator
    session2 = HttpSession.create!(user_agent:'Mozilla 34.1')
    observable2 = Observable.create!(object: session2)
    assert_equal 0, session2.total_sightings
    
    # No observable
    session3 = HttpSession.create!(user_agent:'Mozilla 34.2')
    assert_equal 0, session3.total_sightings
  end
  
  test "total_sightings returns count from one indicator" do
    @session1.reload
    
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting')
    @indicator1.sightings << sight1
    
    assert_equal 1, @session1.total_sightings
  end
  
  test "total_sightings returns count from multiple indicators" do
    @session1.reload
    
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 1')
    sight2 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 2')
    @indicator1.sightings << sight1
    @indicator1.sightings << sight2
    
    indicator2 = Indicator.create(title:"A2",description:"B2",indicator_type:"Benign")
    observable2 = Observable.create(indicator: indicator2, object: @session1)
    
    sight3 = Sighting.create(sighted_at: Time.now, description: 'Test Soghting 2')
    indicator2.sightings << sight3
    
    assert_equal 3, @session1.total_sightings
  end
end
