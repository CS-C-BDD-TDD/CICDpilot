require 'test_helper'

class EmailMessageTest < ActiveSupport::TestCase
  def setup
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    setup_api_user
    @indicator1 = Indicator.create(title:"A",description:"B",indicator_type:"Benign")
    @email1 = EmailMessage.create!(subject:'a')
    @observable1 = Observable.create(indicator: @indicator1, object: @email1)
  end
  
  def teardown
    @observable1 = nil
    @indicator1 = nil
    @email1 = nil
    ::Sunspot.session = ::Sunspot.session.original_session
  end

  test "get list of indicators" do
    @email1.reload
    assert @email1.indicators == [@indicator1]
  end

  test "get list of observables" do
    assert @email1.observables == [@observable1]
  end
  
  test "total_sightings returns 0 with no sightings" do
    @email1.reload
    
    # No sightings
    assert_equal 0, @email1.total_sightings
    
    # No indicator
    email2 = EmailMessage.create!(subject:'b')
    observable2 = Observable.create!(object: email2)
    email2.reload
    assert_equal 0, email2.total_sightings
    
    # No observable
    email3 = EmailMessage.create!(subject:'c')
    assert_equal 0, email3.total_sightings
  end
  
  test "total_sightings returns count from one indicator" do
    @email1.reload
    
    sight1 = Sighting.create(sighted_at: Time.now, description: 
    'Test Sighting')
    @indicator1.sightings << sight1
    
    assert_equal 1, @email1.total_sightings
  end
  
  test "total_sightings returns count from multiple indicators" do
    @email1.reload
    
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 1')
    sight2 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 2')
    @indicator1.sightings << sight1
    @indicator1.sightings << sight2
    
    indicator2 = Indicator.create(title:"A2",description:"B2",indicator_type:"Benign")
    observable2 = Observable.create(indicator: indicator2, object: @email1)
    
    sight3 = Sighting.create(sighted_at: Time.now, description: 'Test Soghting 2')
    indicator2.sightings << sight3
    
    assert_equal 3, @email1.total_sightings
  end
end
