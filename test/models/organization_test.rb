require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  def setup
    setup_api_user
  end

  test "get organization from a user" do
    assert @user.organization == Organization.first
  end

  test "get list of users from organization" do
    before = Organization.first.users.count
    u = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    after = Organization.first.users.count
    assert after - before == 1
  end
end
