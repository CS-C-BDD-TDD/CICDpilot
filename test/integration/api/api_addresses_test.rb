require 'test_helper'

class ApiAddressesTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of addresses" do
    address1 = Address.create!(address_value_raw: "1.2.3.4")
    address2 = Address.create!(address_value_raw: "1.2.3.5")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: address1)

    get("/addresses",nil,@headers)
    result = JSON.parse(response.body)['addresses']
    add_resp = result.second

    assert_json_address(add_resp,address1)
    assert_json_address(result.first,address2)
    assert !result.first.has_key?("indicators")
  end

  test "get single address" do
    address = Address.create!(address_value_raw: "1.2.3.4")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: address)

    get("/addresses/#{address.cybox_object_id}",nil,@headers)
    add_resp = JSON.parse(response.body)

    assert_json_address(add_resp,address)

    assert_json_audit(add_resp['audits'][0],address.audits.first)

    ind_resp = add_resp['indicators'].first
    assert_json_indicator(ind_resp,indicator)
    assert !ind_resp.has_key?("observables")
  end

  test "create an address" do
    data = { address_input: "1.2.3.4" }
    post "/addresses", data, @headers
    assert response.status == 200
    assert Address.count == 1
    assert_json_address(JSON.parse(response.body),Address.first)
  end

  test "pagination of addresses" do
    address1 = Address.create!(address_value_raw: "1.2.3.4")
    address2 = Address.create!(address_value_raw: "1.2.3.5")

    get("/addresses?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['addresses']
    get("/addresses?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['addresses']

    assert_json_address(result1.first,address2)
    assert_json_address(result2.first,address1)
  end
end
