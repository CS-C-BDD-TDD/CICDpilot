require 'test_helper'

class ApiMutexTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of mutexes" do
    mutex1 = CyboxMutex.create!(name: "Mutex 1")
    mutex2 = CyboxMutex.create!(name: "Mutex 2")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: mutex1)

    get("/mutexes",nil,@headers)
    result = JSON.parse(response.body)['mutexes']
    mutex_resp = result.second

    assert_json_mutex(mutex_resp,mutex1)
    assert_json_mutex(result.first,mutex2)
  end

  test "get single mutex" do
    mutex = CyboxMutex.create!(name: "Mutex")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: mutex)

    get("/mutexes/#{mutex.cybox_object_id}",nil,@headers)
    mutex_resp = JSON.parse(response.body)

    assert_json_mutex(mutex_resp,mutex)
    assert_json_audit(mutex_resp['audits'][0],mutex.audits.first)

    ind_resp = mutex_resp['indicators'].first
    assert_json_indicator(ind_resp,indicator)
    assert !ind_resp.has_key?("observables")
  end

  test "create a mutex" do
    data = { name: "Mutex" }
    post "/mutexes", data, @headers
    assert response.status == 200
    assert CyboxMutex.count == 1
    assert_json_mutex(JSON.parse(response.body),CyboxMutex.first)
  end

  test "pagination of mutexes" do
    mutex1 = CyboxMutex.create!(name: "Mutex 1")
    mutex2 = CyboxMutex.create!(name: "Mutex 2")

    get("/mutexes?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['mutexes']
    get("/mutexes?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['mutexes']

    assert_json_mutex(result1.first,mutex2)
    assert_json_mutex(result2.first,mutex1)
  end
end
