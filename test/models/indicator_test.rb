require 'test_helper'

class IndicatorTest < ActiveSupport::TestCase
  def setup
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
    setup_api_user
    @indicator1 = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
  end
  
  def teardown
    ::Sunspot.session = ::Sunspot.session.original_session
  end

  test "get list of observables" do
    d1 = Domain.create!(name_input:'a',name_condition:'Equals')
    a1 = Address.create!(address_input:'1.2.3.4')
    o1 = Observable.create!(indicator: @indicator1, object: d1)
    o2 = Observable.create!(indicator: @indicator1, object: a1)
    @indicator1.reload
    assert @indicator1.observables.map{|o|o.id}.sort == [o1, o2].map{|o|o.id}.sort
  end

  test "get list of domains" do
    d1 = Domain.create!(name_input:'a',name_condition:'Equals')
    o1 = Observable.create!(indicator: @indicator1, object: d1)
    @indicator1.reload
    assert @indicator1.domains == [d1]
  end

  test "get list of addresses" do
    a1 = Address.create!(address_input:'1.2.3.4')
    o1 = Observable.create!(indicator: @indicator1, object: a1)
    @indicator1.reload
    assert @indicator1.addresses == [a1]
  end

  test "get list of uris" do
    u1 = Uri.create!(uri_input:'http://www.cnn.com')
    o1 = Observable.create!(indicator: @indicator1, object: u1)
    @indicator1.reload
    assert @indicator1.uris == [u1]
  end

  test "get list of emails" do
    e1 = EmailMessage.create!(subject:'a')
    o1 = Observable.create!(indicator: @indicator1, object: e1)
    @indicator1.reload
    assert @indicator1.email_messages == [e1]
  end

  test "get list of dns records" do
    d1 = DnsRecord.create!(address_input:'1.2.3.4',address_class:'IN',domain_input:'a',entry_type:'A')
    o1 = Observable.create!(indicator: @indicator1, object: d1)
    @indicator1.reload
    assert @indicator1.dns_records == [d1]
  end

  test "destroying an indicator removes the link to the package and link to observables, but not the package or the observable" do
    d = DnsRecord.create!(address_input:'1.2.3.4',address_class:'IN',domain_input:'a',entry_type:'A')
    o = Observable.create!(indicator: @indicator1, object: d)
    p = StixPackage.create!(title:"Package A")
    p.indicators << @indicator1
    before_packages = StixPackage.count
    before_link_packages = IndicatorsPackage.count
    before_link_observables = Observable.count
    before_observable = DnsRecord.count
    @indicator1.reload # Observable may not be present here without reloading, which means it isn't destroyed
    @indicator1.destroy
    after_packages = StixPackage.count
    after_link_packages = IndicatorsPackage.count
    after_link_observables = Observable.count
    after_observable = DnsRecord.count
    assert after_packages - before_packages == 0
    assert after_link_packages - before_link_packages == -1
    assert after_link_observables - before_link_observables == -1
    assert after_observable - before_observable == 0
  end

  test "total_sightings returns 0 with no sightings" do
    # No Observable, no Sightings
    assert_equal 0, @indicator1.total_sightings

    # Observable, no Sightings
    u1 = Uri.create(uri_input: 'http://www.cnn.com')
    o1 = Observable.create!(indicator: @indicator1, object: u1)
    @indicator1.reload
    assert_equal 1, @indicator1.observables.size
    assert_equal 0, @indicator1.total_sightings
  end
  
  test "total_sightings returns count from own sightings" do
    # Sightings, no Observable
    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting')
    @indicator1.sightings << sight1
    assert_equal 1, @indicator1.total_sightings

    # Gets the same sightings with an Observable    
    u1 = Uri.create(uri_input: 'http://www.cnn.com')
    o1 = Observable.create(indicator: @indicator1, object: u1)
    @indicator1.reload
    assert_equal 1, @indicator1.total_sightings
  end
  
  test "total_sightings returns count from multiple indicators" do
    u1 = Uri.create(uri_input:'http://www.cnn.com')
    o1 = Observable.create(indicator: @indicator1, object: u1)

    sight1 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 1')
    sight2 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 2')
    @indicator1.sightings << sight1
    @indicator1.sightings << sight2
    
    indicator2 = Indicator.create(title:"A2",description:"B2",indicator_type:"Benign")
    o2 = Observable.create(indicator: indicator2, object: u1)
    
    sight3 = Sighting.create(sighted_at: Time.now, description: 'Test Sighting 2')
    indicator2.sightings << sight3
    
    @indicator1.reload
    assert_equal 3, @indicator1.total_sightings
  end
end
