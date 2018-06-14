require 'test_helper'

class NetworkConnectionTest < ActiveSupport::TestCase
  def setup
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    setup_api_user
    @indicator1 = Indicator.create(title:"A",description:"B",indicator_type:"Benign")
    @network1 = NetworkConnection.create!(dest_socket_address: '1.2.3.4', dest_socket_is_spoofed: true,
                                   dest_socket_port: '80', source_socket_hostname: 'rogueciap.com', source_socket_port: '80',
                                   layer3_protocol: 'IPv4', layer4_protocol: 'TCP', layer7_protocol: 'HTTP')
    @observable1 = Observable.create(indicator: @indicator1, object: @network1)
  end
  
  def teardown
    @observable1 = nil
    @indicator1 = nil
    @network1 = nil
    ::Sunspot.session = ::Sunspot.session.original_session
  end

  test "get list of indicators" do
    @network1.reload
    assert @network1.indicators == [@indicator1]
  end

  test "get list of observables" do
    assert @network1.observables == [@observable1]
  end
  
  test "total_sightings returns 0 with no sightings" do
    @network1.reload
    
    # No sightings
    assert_equal 0, @network1.total_sightings
    
    # No indicator
    network2 = NetworkConnection.create!(dest_socket_address: '10.20.30.40', dest_socket_is_spoofed: true,
                                   dest_socket_port: '80', source_socket_hostname: 'rogueciap.com', source_socket_port: '80',
                                   layer3_protocol: 'IPv4', layer4_protocol: 'TCP', layer7_protocol: 'HTTP')
    observable2 = Observable.create!(object: network2)
    assert_equal 0, network2.total_sightings
    
    # No observable
    network3 = NetworkConnection.create!(dest_socket_address: '11.21.31.41', dest_socket_is_spoofed: true,
                                   dest_socket_port: '80', source_socket_hostname: 'rogueciap.com', source_socket_port: '80',
                                   layer3_protocol: 'IPv4', layer4_protocol: 'TCP', layer7_protocol: 'HTTP')
    assert_equal 0, network3.total_sightings
  end
  
  test "total_sightings returns count from one indicator" do
    @network1.reload
    
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting')
    @indicator1.sightings << sight1
    
    assert_equal 1, @network1.total_sightings
  end
  
  test "total_sightings returns count from multiple indicators" do
    @network1.reload
    
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 1')
    sight2 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 2')
    @indicator1.sightings << sight1
    @indicator1.sightings << sight2
    
    indicator2 = Indicator.create(title:"A2",description:"B2",indicator_type:"Benign")
    observable2 = Observable.create(indicator: indicator2, object: @network1)
    
    sight3 = Sighting.create(sighted_at: Time.now, description: 'Test Soghting 2')
    indicator2.sightings << sight3
    
    assert_equal 3, @network1.total_sightings
  end
end