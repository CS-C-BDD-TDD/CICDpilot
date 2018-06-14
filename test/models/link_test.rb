require 'test_helper'

class LinkTest < ActiveSupport::TestCase
  def setup
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    setup_api_user
    @indicator1 = Indicator.create(title:"A",description:"B",indicator_type:"Benign")
    @uri1 = Uri.create!(uri_input:'http://www.cnn.com')
    @link1 = Link.create!(uri: @uri1, label: 'label 1')
    @observable1 = Observable.create(indicator: @indicator1, object: @link1)
  end
  
  def teardown
    @observable1 = nil
    @indicator1 = nil
    @link1 = nil
    @uri1 = nil
    ::Sunspot.session = ::Sunspot.session.original_session
  end

  test "get list of indicators" do
    assert @link1.indicators == [@indicator1]
  end

  test "get list of observables" do
    assert @link1.observables == [@observable1]
  end
  
  test "total_sightings returns 0 with no sightings" do
    # No sightings
    assert_equal 0, @link1.total_sightings
    
    # No indicator
    link2 = Link.create!(uri: @uri1, label: 'label 2')
    observable2 = Observable.create!(object: link2)
    assert_equal 0, link2.total_sightings
    
    # No observable
    link3 = Link.create!(uri: @uri1, label: 'label 3')
    assert_equal 0, link3.total_sightings
  end
  
  test "total_sightings returns count from one indicator" do
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting')
    @indicator1.sightings << sight1
    
    assert_equal 1, @link1.total_sightings
  end
  
  test "total_sightings returns count from multiple indicators" do
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 1')
    sight2 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 2')
    @indicator1.sightings << sight1
    @indicator1.sightings << sight2
    
    indicator2 = Indicator.create(title:"A2",description:"B2",indicator_type:"Benign")
    observable2 = Observable.create(indicator: indicator2, object: @link1)
    
    sight3 = Sighting.create(sighted_at: Time.now, description: 'Test Soghting 2')
    indicator2.sightings << sight3
    
    assert_equal 3, @link1.total_sightings
  end
end
