require 'test_helper'

class ApiUriTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of uris" do
    uri1 = Uri.create!(uri_input: "http://www.google.com/file.html")
    uri2 = Uri.create!(uri_input: "http://www.yahoo.com/file.html")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: uri1)

    get("/uris",nil,@headers)
    result = JSON.parse(response.body)['uris']
    uri_resp = result.second

    assert_json_uri(uri_resp,uri1)
    assert_json_uri(result.first,uri2)
  end

  test "get single uri" do
    uri = Uri.create!(uri_input: "http://www.google.com/file.html")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: uri)

    get("/uris/#{uri.cybox_object_id}",nil,@headers)
    uri_resp = JSON.parse(response.body)

    assert_json_uri(uri_resp,uri)
    assert_json_audit(uri_resp['audits'][0],uri.audits.first)

    ind_resp = uri_resp['indicators'].first
    assert_json_indicator(ind_resp,indicator)
    assert !ind_resp.has_key?("observables")
  end

  test "create a uri" do
    data = { uri_input: "http://www.google.com/file.html" }
    post "/uris", data, @headers
    assert response.status == 200
    assert Uri.count == 1
    assert_json_uri(JSON.parse(response.body),Uri.first)
  end

  test "pagination of uris" do
    uri1 = Uri.create!(uri_input: "http://www.google.com/file.html")
    uri2 = Uri.create!(uri_input: "http://www.yahoo.com/file.html")

    get("/uris?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['uris']
    get("/uris?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['uris']

    assert_json_uri(result1.first,uri2)
    assert_json_uri(result2.first,uri1)
  end
end
