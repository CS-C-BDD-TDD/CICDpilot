require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    setup_api_user
  end

  test "Two active users with the same username can't exist" do
    u1 = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    u2 = User.new(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    assert !u2.valid?
  end

  test "Two users with the same username can exist if one is disabled" do
    u1 = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', disabled_at: Time.now, organization: Organization.first)
    u2 = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    assert u2.id.present?
  end

  test "A username can be reused" do
    u1 = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    u1.enable_disable
    u2 = User.create!(username: 'a', email: 'a@i.app', first_name: 'A', last_name: 'A', organization: Organization.first)
    assert u2.id.present?
  end
end
