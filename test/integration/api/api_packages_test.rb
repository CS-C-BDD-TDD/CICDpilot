require 'test_helper'

class ApiStixPackagesTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "get list of packages" do
    package1 = StixPackage.create!(title:"A",description:"B",short_description:'b')
    package2 = StixPackage.create!(title:"B",description:"C",short_description:'c')
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    IndicatorsPackage.create!(indicator: indicator, stix_package: package1)
    uri = Uri.create!(uri_input: 'http://www.google.com')
    observable = Observable.create!(indicator: indicator, object: uri)

    get("/stix_packages",nil,@headers)
    result = JSON.parse(response.body)['stix_packages']

    assert_json_package(result.first,package1)
    assert_json_package(result.second,package2)
  end

  test "get single package" do
    package = StixPackage.create!(title:"A",description:"B",short_description:'b')
    indicator = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    IndicatorsPackage.create!(indicator: indicator, stix_package: package)
    uri = Uri.create!(uri_input: 'http://www.google.com')
    observable = Observable.create!(indicator: indicator, object: uri)

    get("/stix_packages/#{package.stix_id}",nil,@headers)
    pack_resp = JSON.parse(response.body)

    assert_json_package(pack_resp,package)
    assert_json_audit(pack_resp['audits'][0],package.audits.first)

    ind_resp = pack_resp['indicators'][0]
    assert_json_indicator(ind_resp,indicator)
    obs_resp = ind_resp["observables"][0]
    assert_json_observable(obs_resp,observable)
    assert_json_uri(obs_resp["uri"],uri)
  end

  test "create a package" do
    data = { title: "A", description: "B", short_description: "b" }
    post "/stix_packages", data, @headers
    assert response.status == 200
    assert StixPackage.count == 1
    assert_json_package(JSON.parse(response.body),StixPackage.first)
  end

  test "update a package" do
    package = StixPackage.create!(title:"A",description:"B",short_description:"b")
    data = { description: "updated description" }
    put "/stix_packages/#{package.stix_id}", data, @headers
    assert response.status == 200
    pack_resp = JSON.parse(response.body)
    package.description = "updated description"
    assert_json_package(pack_resp,package)
  end

  test "pagination of packages" do
    package1 = StixPackage.create!(title:"A",description:"B",short_description:'b')
    package2 = StixPackage.create!(title:"B",description:"C",short_description:'c')

    get("/stix_packages?amount=1&offset=0",nil,@headers)
    result1 = JSON.parse(response.body)['stix_packages']
    get("/stix_packages?amount=1&offset=1",nil,@headers)
    result2 = JSON.parse(response.body)['stix_packages']

    assert_json_package(result1.first,package2)
    assert_json_package(result2.first,package1)
  end
end
