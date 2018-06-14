require 'test_helper'

class StixPackageTest < ActiveSupport::TestCase
  def setup
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    setup_api_user
  end

  def teardown
    ::Sunspot.session = ::Sunspot.session.original_session
  end

  test "deleting a package removes the stix_indicator_package, but not the indicator" do
    i = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    p = StixPackage.create!(title:"Package A")
    p.indicators << i
    before_link = IndicatorsPackage.count
    before_ind = Indicator.count
    p.destroy
    after_link = IndicatorsPackage.count
    after_ind = Indicator.count
    assert after_link - before_link == -1
    assert after_ind - before_ind == 0
  end

  test "a uploaded package gets a uploaded badge" do
    p = StixPackage.create!(title:"Uploaded Package", uploaded_file_id: "32")
    p.reload
    assert p.badge_statuses.collect(&:badge_name).include?("UPLOADED")
  end

  test "a mifr package gets a mifr badge" do 
    p = StixPackage.create!(title:"MIFR Package", is_mifr: true)
    p.reload
    assert p.badge_statuses.collect(&:badge_name).include?("MIFR")
  end

  test "a ciscp package gets a ciscp badge" do 
    p = StixPackage.create!(title:"CISCP Package", is_ciscp: true)
    p.reload
    assert p.badge_statuses.collect(&:badge_name).include?("CISCP")
  end

  test "a read only package gets a read only badge" do 
    p = StixPackage.create!(title:"Read Only Package", read_only: true)
    p.reload
    assert p.badge_statuses.collect(&:badge_name).include?("READ ONLY")
  end

  test "a package with ingested feed name gets a feed badge" do 
    p = StixPackage.create!(title:"Package A", feeds: "AIS,FEDGOV")
    p.reload
    assert p.badge_statuses.collect(&:badge_name).include?("AIS")
    assert p.badge_statuses.collect(&:badge_name).include?("FEDGOV")
  end
end
