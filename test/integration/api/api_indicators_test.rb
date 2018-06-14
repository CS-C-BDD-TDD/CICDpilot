require 'test_helper'

class ApiIndicatorsTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of indicators" do
    indicator1 = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    indicator2 = Indicator.create!(title:"B",description:"C",indicator_type:"Anonymization")
    uri = Uri.create!(uri_input: 'http://www.google.com')
    observable = Observable.create!(indicator: indicator1, object: uri)

    get("/indicators",nil,@headers)
    result = JSON.parse(response.body)['indicators']
    first_indicator = result.detect {|r| r['title']==indicator1.title}
    assert first_indicator['title'] == indicator1.title
    second_indicator = result.detect {|r| r['title']==indicator2.title}
    assert second_indicator['title'] == indicator2.title

    obs_resp = first_indicator["observables"][0]
    assert_json_observable(obs_resp,observable)
    assert_json_uri(obs_resp["uri"],uri)
  end

  test "get single indicator" do
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    uri = Uri.create!(uri_input: 'http://www.google.com')
    observable = Observable.create!(indicator: indicator, object: uri)

    get("/indicators/#{indicator.stix_id}",nil,@headers)
    ind_resp = JSON.parse(response.body)

    assert_json_indicator(ind_resp,indicator)
    assert_json_audit(ind_resp['audits'][0],indicator.audits.first)
    obs_resp = ind_resp["observables"][0]
    assert_json_observable(obs_resp,observable)
    assert_json_uri(obs_resp["uri"],uri)
  end

  test "create an indicator" do
    data = { title: "A", description: "B", indicator_type: "Benign" }
    post "/indicators", data, @headers
    assert response.status == 201
    assert Indicator.count == 1
    assert_json_indicator(JSON.parse(response.body),Indicator.first)
  end

  test "create an indicator with a DMS label and retrieve by that DMS label" do
    data = { stix_id: 'DOA:994d60c0-b0b1-11e4-af90-12e3f512a338', title: "A", description: "B", indicator_type: "Benign", dms_label: 'DaveGormanLabel' }
    post "/indicators", data, @headers
    get("/indicators?dms_label=DaveGormanLabel",nil,@headers)
    assert response.status == 200
    assert JSON.parse(response.body)["indicators"].count == 1
    assert JSON.parse(response.body)["indicators"].first["dms_label"] == 'DaveGormanLabel'
    get("/indicators?dms_label=InvalidDMSLabel",nil,@headers)
    tc = JSON.parse(response.body)["metadata"]["total_count"]
    assert (tc == 0), "JSON for Invalid Label is #{tc} (#{tc.class.to_s})"
  end

  test "time ranges" do
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    get("/indicators?ebt=#{URI.encode(1.day.ago.to_s)}&iet=#{URI.encode(1.day.ago.to_s)}",nil,@headers)
    assert JSON.parse(response.body)["metadata"]["total_count"] == 0
    get("/indicators?ebt=#{URI.encode(1.day.ago.to_s)}&iet=#{URI.encode((Time.now+1.day).to_s)}",nil,@headers)
    assert JSON.parse(response.body)["metadata"]["total_count"] == 1
    get("/indicators?ebt=#{URI.encode((Time.now+1.day).to_s)}&iet=#{URI.encode((Time.now+2.days).to_s)}",nil,@headers)
    assert JSON.parse(response.body)["metadata"]["total_count"] == 0
  end

  test "update an indicator" do
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    data = { description: "updated description" }
    put "/indicators/#{indicator.stix_id}", data, @headers
    assert response.status == 200
    ind_resp = JSON.parse(response.body)
    indicator.description = "updated description"
    assert_json_indicator(ind_resp,indicator)
  end

  test "pagination of indicators" do
    indicator1 = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    indicator2 = Indicator.create!(title:"B",description:"C",indicator_type:"Anonymization")

    get("/indicators?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['indicators']
    get("/indicators?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['indicators']

    assert result1.first['title'] == indicator2.title
    assert result2.first['title'] == indicator1.title
  end
end
