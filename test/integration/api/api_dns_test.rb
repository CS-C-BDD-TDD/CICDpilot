require 'test_helper'

class ApiDnsTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of dns records" do
    dns1 = DnsRecord.create!(address_value_raw: "1.2.3.4", domain_raw: "cnn.com")
    dns2 = DnsRecord.create!(address_value_raw: "1.2.3.5", domain_raw: "google.com")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: dns1)

    get("/dns_records",nil,@headers)
    result = JSON.parse(response.body)['dns_records']
    dns_resp = result.second

    assert_json_dns_record(dns_resp,dns1)
    assert_json_dns_record(result.first,dns2)
  end

  test "get single dns record" do
    dns = DnsRecord.create!(address_value_raw: "1.2.3.4", domain_raw: "cnn.com")
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: dns)

    get("/dns_records/#{dns.cybox_object_id}",nil,@headers)
    dns_resp = JSON.parse(response.body)

    assert_json_dns_record(dns_resp,dns)

    assert_json_audit(dns_resp['audits'][0],dns.audits.first)

    ind_resp = dns_resp['indicators'].first
    assert_json_indicator(ind_resp,indicator)
    assert !ind_resp.has_key?("observables")
  end

  test "create a dns record" do
    data = { address_input: "1.2.3.4", domain_input: "cnn.com" }
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    post "/dns_records", data, @headers
    assert response.status == 200
    assert DnsRecord.count == 1
    assert_json_dns_record(JSON.parse(response.body),DnsRecord.first)
  end

  test "pagination of dns records" do
    dns1 = DnsRecord.create!(address_value_raw: "1.2.3.4", domain_raw: "cnn.com")
    dns2 = DnsRecord.create!(address_value_raw: "1.2.3.5", domain_raw: "google.com")

    get("/dns_records?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['dns_records']
    get("/dns_records?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['dns_records']

    assert_json_dns_record(result1.first,dns2)
    assert_json_dns_record(result2.first,dns1)
  end
end
