require 'test_helper'

class ApiHttpSessionTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of http sessions" do
    http_session1 = HttpSession.create!(user_agent: "Mozilla")
    http_session2 = HttpSession.create!(user_agent: "Internet Explorer")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: http_session1)

    get("/http_sessions",nil,@headers)
    result = JSON.parse(response.body)['http_sessions']
    http_session_resp = result.second

    assert_json_http_session(http_session_resp,http_session1)
    assert_json_http_session(result.first,http_session2)
  end

  test "get single http session" do
    http_session = HttpSession.create!(user_agent: "Mozilla")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: http_session)

    get("/http_sessions/#{http_session.cybox_object_id}",nil,@headers)
    http_session_resp = JSON.parse(response.body)

    assert_json_http_session(http_session_resp,http_session)
    assert_json_audit(http_session_resp['audits'][0],http_session.audits.first)

    ind_resp = http_session_resp['indicators'].first
    assert_json_indicator(ind_resp,indicator)
    assert !ind_resp.has_key?("observables")
  end

  test "create an http session" do
    data = { user_agent: "Mozilla" }
    post "/http_sessions", data, @headers
    assert response.status == 200
    assert HttpSession.count == 1
    assert_json_http_session(JSON.parse(response.body),HttpSession.first)
  end

  test "pagination of http sessions" do
    http_session1 = HttpSession.create!(user_agent: "Mozilla")
    http_session2 = HttpSession.create!(user_agent: "Internet Explorer")

    get("/http_sessions?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['http_sessions']
    get("/http_sessions?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['http_sessions']

    assert_json_http_session(result1.first,http_session2)
    assert_json_http_session(result2.first,http_session1)
  end
end
