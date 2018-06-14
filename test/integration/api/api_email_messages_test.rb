require 'test_helper'

class ApiEmailMessagesTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of emails" do
    email1 = EmailMessage.create!(subject:'a')
    email2 = EmailMessage.create!(subject:'b')
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: email1)

    get("/email_messages",nil,@headers)
    result = JSON.parse(response.body)['email_messages']
    email_resp = result.second

    assert_json_email_message(email_resp,email1)
    assert_json_email_message(result.first,email2)
  end

  test "get single email" do
    email = EmailMessage.create!(subject:'a')
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    observable = Observable.create!(indicator: indicator, object: email)

    get("/email_messages/#{email.cybox_object_id}",nil,@headers)
    email_resp = JSON.parse(response.body)

    assert_json_email_message(email_resp,email)
    assert_json_audit(email_resp['audits'][0],email.audits.first)

    ind_resp = email_resp['indicators'].first
    assert_json_indicator(ind_resp,indicator)
    assert !ind_resp.has_key?("observables")
  end

  test "create an email" do
    data = { subject: 'a' }
    post "/email_messages", data, @headers
    assert response.status == 200
    assert EmailMessage.count == 1
    assert_json_email_message(JSON.parse(response.body),EmailMessage.first)
  end

  test "pagination of emails" do
    email1 = EmailMessage.create!(subject:'a')
    email2 = EmailMessage.create!(subject:'b')

    get("/email_messages?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['email_messages']
    get("/email_messages?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['email_messages']

    assert_json_email_message(result1.first,email2)
    assert_json_email_message(result2.first,email1)
  end
end
