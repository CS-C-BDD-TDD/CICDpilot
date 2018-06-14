require 'test_helper'

class ApiDomainsTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of domains" do
    domain1 = Domain.create!(name_raw: "www.google.com", name_condition: "Equals")
    domain2 = Domain.create!(name_raw: "www.yahoo.com", name_condition: "Equals")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: domain1)

    get("/domains",nil,@headers)
    result = JSON.parse(response.body)['domains']
    dom_resp = result.second

    assert_json_domain(dom_resp,domain1)
    assert_json_domain(result.first,domain2)
  end

  test "get single domain" do
    domain = Domain.create!(name_raw: "www.google.com", name_condition: "Equals")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: domain)

    get("/domains/#{domain.cybox_object_id}",nil,@headers)
    dom_resp = JSON.parse(response.body)

    assert_json_domain(dom_resp,domain)
    assert_json_audit(dom_resp['audits'][0],domain.audits.first)

    ind_resp = dom_resp['indicators'].first
    assert_json_indicator(ind_resp,indicator)
    assert !ind_resp.has_key?("observables")
  end

  test "create a domain" do
    data = { name_input: "www.newdomain.com", name_condition: 'Equals' }
    post "/domains", data, @headers
    assert response.status == 200
    assert Domain.count == 1
    assert_json_domain(JSON.parse(response.body),Domain.first)
  end

  test "pagination of domains" do
    domain1 = Domain.create!(name_raw: "www.google.com", name_condition: "Equals")
    domain2 = Domain.create!(name_raw: "www.yahoo.com", name_condition: "Equals")

    get("/domains?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['domains']
    get("/domains?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['domains']

    assert_json_domain(result1.first,domain2)
    assert_json_domain(result2.first,domain1)
  end
end
