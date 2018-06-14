require 'test_helper'

class ApiNetworkConnectionTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of network connections" do
    network_connection1 = NetworkConnection.create!(dest_socket_address: '1.2.3.4', dest_socket_is_spoofed: true,
                                                    dest_socket_port: '80', source_socket_hostname: 'rogueciap.com', source_socket_port: '80',
                                                    layer3_protocol: 'IPv4', layer4_protocol: 'TCP', layer7_protocol: 'HTTP')
    network_connection2 = NetworkConnection.create!(dest_socket_address: '2.3.4.5', dest_socket_is_spoofed: false,
                                                   dest_socket_port: '8080',
                                                   source_socket_address: '5.4.3.2', source_socket_port: '1966',
                                                   layer4_protocol: 'UDP')
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: network_connection1)

    get("/network_connections",nil,@headers)
    result = JSON.parse(response.body)['network_connections']
    network_connection_resp = result.second

    assert_json_network_connection(network_connection_resp,network_connection1)
    assert_json_network_connection(result.first,network_connection2)
  end

  test "get single network connection" do
    network_connection = NetworkConnection.create!(dest_socket_address: '1.2.3.4', dest_socket_is_spoofed: true,
                                                   dest_socket_port: '80', source_socket_hostname: 'rogueciap.com', source_socket_port: '80',
                                                   layer3_protocol: 'IPv4', layer4_protocol: 'TCP', layer7_protocol: 'HTTP')
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: network_connection)

    get("/network_connections/#{network_connection.cybox_object_id}",nil,@headers)
    network_connection_resp = JSON.parse(response.body)

    assert_json_network_connection(network_connection_resp,network_connection)
    assert_json_audit(network_connection_resp['audits'][0],network_connection.audits.first)

    ind_resp = network_connection_resp['indicators'].first
    assert_json_indicator(ind_resp,indicator)
    assert !ind_resp.has_key?("observables")
  end

  test "create a network connection" do
    data = { user_agent: "Mozilla" }
    data = { dest_socket_address: '1.2.3.4', dest_socket_is_spoofed: true, dest_socket_port: '80',
             source_socket_address: '4.3.2.1', source_socket_port: '80', layer4_protocol: 'TCP'}
    post "/network_connections", data, @headers
    assert response.status == 200
    assert NetworkConnection.count == 1
    assert_json_network_connection(JSON.parse(response.body),NetworkConnection.first)
  end

  test "pagination of network connections" do
    network_connection1 = NetworkConnection.create!(dest_socket_address: '1.2.3.4', dest_socket_is_spoofed: true,
                                                    dest_socket_port: '80', source_socket_hostname: 'rogueciap.com', source_socket_port: '80',
                                                    layer3_protocol: 'IPv4', layer4_protocol: 'TCP', layer7_protocol: 'HTTP')
    network_connection2 = NetworkConnection.create!(dest_socket_address: '2.3.4.5', dest_socket_is_spoofed: false,
                                                   dest_socket_port: '8080',
                                                   source_socket_address: '5.4.3.2', source_socket_port: '1966',
                                                   layer4_protocol: 'UDP')

    get("/network_connections?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['network_connections']
    get("/network_connections?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['network_connections']

    assert_json_network_connection(result1.first,network_connection2)
    assert_json_network_connection(result2.first,network_connection1)
  end
end
