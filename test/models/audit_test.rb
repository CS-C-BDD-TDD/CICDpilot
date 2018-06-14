require 'test_helper'

class AuditTest < ActiveSupport::TestCase
  def setup
    setup_api_user
  end

  test "creating an indicator creates an audit" do
    before = Audit.count
    i = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    after = Audit.count
    assert after - before == 1
    assert i.audits.count == 1
  end

  test "creating a package creates an audit" do
    before = Audit.count
    p = StixPackage.create!(title: 'a',description: "b",short_description: "c")
    after = Audit.count
    assert (after - before == 1), "After - Before = #{after - before}"
    assert (p.audits.count == 1), "Package audit counts = #{p.audits.count}"
  end

  test "creating a domain creates an audit" do
    before = Audit.count
    d = Domain.create!(name_raw: "www.google.com", name_condition: 'Equals')
    after = Audit.count
    assert after - before == 1
    assert d.audits.count == 1
  end

  test "creating an address creates an audit" do
    before = Audit.count
    a = Address.create!(address_value_raw: "::1")
    after = Audit.count
    assert after - before == 1
    assert a.audits.count == 1
  end

  test "creating a user creates an audit" do
    before = Audit.count
    u = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    after = Audit.count
    assert after - before == 3
    assert u.audits.count == 2
  end

  test "editing a user creates an audit" do
    before = Audit.count
    u = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    u.first_name = "Jake"
    u.save
    after = Audit.count
    assert after - before == 4
    assert u.audits.count == 3
  end

  test "linking an observable to an indicator creates a link audit" do
    before = Audit.count
    a = Address.create!(address_value_raw: "::1")
    i = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    o = Observable.create!(indicator: i, object: a)
    after = Audit.count
    assert after - before == 4
    assert a.audits.count == 2
    assert i.audits.count == 2
  end

  test "updating an indicator creates an audit" do
    before = Audit.count
    i = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    i.title = "B"
    i.save
    after = Audit.count
    assert after - before == 2
    assert i.audits.count == 2
  end

  test "unlinking an observable to an indicator creates a link audit" do
    before = Audit.count
    a = Address.create!(address_value_raw: "::1")
    i = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    o = Observable.create!(indicator: i, object: a)
    o.destroy
    after = Audit.count
    assert after - before == 6
    assert a.audits.count == 3
    assert i.audits.count == 3
    assert Audit.where(audit_type: 'unlink').count == 2
  end

  test "tagging an indicator creates an audit" do
    before = Audit.count
    t = SystemTag.create!(name:'t')
    i = Indicator.create!(title:"A",description:"B",indicator_type:"Benign", system_tags: [t])
    after = Audit.count
    assert after - before == 4
    assert t.audits.count == 2
    assert i.audits.count == 2
  end

  test "removing a tag from an indicator creates an audit" do
    before = Audit.count
    t = SystemTag.create!(name:'t')
    i = Indicator.create!(title:"A",description:"B",indicator_type:"Benign", system_tags: [t])
    i.update(system_tags: [])
    after = Audit.count
    assert after - before == 6
    assert t.audits.count == 3
    assert i.audits.count == 3
  end

  test "adding an indicator to a package creates an audit" do
    before = Audit.count
    p = StixPackage.create!(title: 'a',description: "b",short_description: "c")
    i = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    p.indicators << i
    after = Audit.count
    assert (after - before == 4), "Error: after - before = #{after - before}"
    assert (p.audits.count == 2), "Error: Package audits = #{p.audits.count}"
    assert (i.audits.count == 2), "Error: Indicator audits = #{i.audits.count}"
  end

  test "removing an indicator from a package creates an audit" do
    p = StixPackage.create!(title: 'a',description: "b",short_description: "c")
    i = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    p.indicators << i
    before = Audit.count
    p.indicators = []
    after = Audit.count
    assert (after - before == 2), "After - Before = #{after - before}"
    assert (p.audits.count == 3), "Package audits = #{p.audits.count}"
    assert (i.audits.count == 3), "Indicator audits = #{i.audits.count}"
  end

  test "adding a user to a group creates an audit" do
    before = Audit.count
    u = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    g = Group.create!(name: 'admins',description:'blank')
    g.users << u
    after = Audit.count
    assert after - before == 6
    assert u.audits.count == 3
    assert g.audits.count == 2
  end

  test "removing a user from a group creates an audit" do
    before = Audit.count
    u = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    g = Group.create!(name: 'admins',description:'blank')
    g.users << u
    g.users = []
    after = Audit.count
    assert after - before == 8
    assert u.audits.count == 4
    assert g.audits.count == 3
  end

  test "removing a user from a group via update creates an audit" do
    before = Audit.count
    u = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    g = Group.create!(name: 'admins',description:'blank')
    g.users << u
    g.update(user_ids: [])
    after = Audit.count
    assert after - before == 8
    assert u.audits.count == 4
    assert g.audits.count == 3
  end

  test "creating a group creates an audit" do
    before = Audit.count
    g = Group.create!(name: 'admins',description:'blank')
    after = Audit.count
    assert after - before == 1
    assert g.audits.count == 1
  end

  test "destroying a group properly adds audits" do
    count = Permission.count
    p = Permission.create!(name:'a',display_name:'b',description:'c')
    g = Group.create!(name: 'admins',description:'blank')
    g.permissions << p
    before = Audit.count
    g.destroy
    after = Audit.count
    assert after - before == 1
    assert p.audits.count == 2
    assert Permission.count == count+1
  end

  test "adding a permission to a group creates an audit" do
    before = Audit.count
    p = Permission.create!(name:'a',display_name:'b',description:'c')
    g = Group.create!(name: 'admins',description:'blank')
    g.permissions << p
    after = Audit.count
    assert after - before == 4
    assert p.audits.count == 2
    assert g.audits.count == 2
  end

  test "removing a permission from a group creates an audit" do
    before = Audit.count
    p = Permission.create!(name:'a',display_name:'b',description:'c')
    g = Group.create!(name: 'admins',description:'blank')
    g.permissions << p
    g.permissions = []
    after = Audit.count
    assert after - before == 6
    assert p.audits.count == 3
    assert g.audits.count == 3
  end

  test "adding a user to an organization creates an audit" do
    o = Organization.create(short_name:'no',long_name:'new_org')
    before = Audit.count
    u = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: o)
    after = Audit.count
    assert after - before == 3
  end

  test "reassigned a user's organization creates audits" do
    o = Organization.create(short_name:'no',long_name:'new_org')
    before = Audit.count
    @user.organization = o
    @user.save
    after = Audit.count
    assert after - before == 3
  end

  test "adding a confidence to an indicator adds an audit" do
    before = Audit.count
    d = Domain.create!(name_input: 'www.google.com',name_condition: 'Equals')
    i = Indicator.create!(title:"A",description:"B",indicator_type:"Benign")
    o = Observable.create!(indicator: i, object: d)
    Confidence.create!(remote_object: i, value: 'high')
    after = Audit.count
    assert after - before == 6
    assert i.audits.count == 3
  end

end
