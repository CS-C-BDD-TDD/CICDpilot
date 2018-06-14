require 'test_helper'

class ApiRegistryTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of registries" do
    registry1 = Registry.create!(hive: 'HKEY_LOCAL_MACHINE', key: 'key 1', registry_values_attributes: [{reg_name: 'name', reg_value: 'value'}])
    registry2 = Registry.create!(hive: 'HKEY_LOCAL_MACHINE', key: 'key 2', registry_values_attributes: [{reg_name: 'name', reg_value: 'value'}])
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: registry1)

    get("/registries",nil,@headers)
    result = JSON.parse(response.body)['registries']
    registry_resp = result.second

    assert_json_registry(registry_resp,registry1)
    assert_json_registry(result.first,registry2)
  end

  test "get single registry" do
    registry = Registry.create!(hive: 'HKEY_LOCAL_MACHINE', key: 'key', registry_values_attributes: [{reg_name: 'name', reg_value: 'value'}])
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: registry)

    get("/registries/#{registry.cybox_object_id}",nil,@headers)
    registry_resp = JSON.parse(response.body)

    assert_json_registry(registry_resp,registry)
    assert_json_audit(registry_resp['audits'][0],registry.audits.first)

    ind_resp = registry_resp['indicators'].first
    assert_json_indicator(ind_resp,indicator)
    assert !ind_resp.has_key?("observables")
  end

  test "create a registry" do
    data = { hive: 'HKEY_LOCAL_MACHINE', key: 'key', registry_values_attributes: [{reg_name: 'name', reg_value: 'value'}] }
    post "/registries", data, @headers
    assert response.status == 200
    assert Registry.count == 1
    assert_json_registry(JSON.parse(response.body),Registry.first)
  end

  test "pagination of registries" do
    registry1 = Registry.create!(hive: 'HKEY_LOCAL_MACHINE', key: 'key 1', registry_values_attributes: [{reg_name: 'name', reg_value: 'value'}])
    registry2 = Registry.create!(hive: 'HKEY_LOCAL_MACHINE', key: 'key 2', registry_values_attributes: [{reg_name: 'name', reg_value: 'value'}])

    get("/registries?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['registries']
    get("/registries?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['registries']

    assert_json_registry(result1.first,registry2)
    assert_json_registry(result2.first,registry1)
  end
end
