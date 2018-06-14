require 'test_helper'

class ApiUsersTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
  end

  def setup_permission
    default_permissions
    @group = Group.create!(name: 'first', description: 'a')
    @permission = Permission.find_by_name('view_user_organization')
    perm = Permission.find_by_name('create_modify_user_organization')
    @user = User.first
    UserGroup.create!(user: @user, group: @group)
    GroupPermission.create!(group: @group, permission: @permission)
    GroupPermission.create!(group: @group, permission: perm)
  end

  def teardown
    @headers = nil
  end

  test "denied without group permission" do
    get("/users",nil,@headers)
    result = JSON.parse(response.body)
    assert result.has_key?('errors')
    assert result['errors'][0] == 'You do not have the ability to view users'
  end

  test "get list of users" do
    setup_permission

    user1 = User.create!(
        username: 'user1',
        first_name: 'A',
        last_name: 'B',
        email: 'you@email.com',
        password: 'P@ssw0rd!',
        password_confirmation: 'P@ssw0rd!',
        organization: Organization.first
    )

    get("/users",nil,@headers)
    result = JSON.parse(response.body)
    user_resp = result.first

    assert_json_user(user_resp,@user)
    assert_json_user(result.second,user1)
  end

  test "get single user" do
    setup_permission

    get("/users/#{@user.id}",nil,@headers)
    user_resp = JSON.parse(response.body)

    assert_json_user(user_resp,@user)
    assert_json_audit(user_resp['audits'][0],@user.audits.first)
    group_resp = user_resp['groups'].find {|x| x['name'] == 'first'}
    assert_json_group(group_resp,@group)
    perm_resp = user_resp['permissions'].find {|x| x['name'] == 'view_user_organization'}
    assert_json_permission(perm_resp,@permission)
  end

  test "create a user" do
    setup_permission
    data = { username: 'user1',
             first_name: 'A',
             last_name: 'B',
             email: 'you@email.com',
             password: 'P@ssw0rd!',
             password_confirmation: 'P@ssw0rd!',
             organization_guid: Organization.first.guid }
    post "/users", data, @headers
    assert response.status == 200
    assert User.count == 2
    assert_json_user(JSON.parse(response.body),User.last)
  end

  test "update a user" do
    setup_permission
    user1 = User.create!(
        username: 'user1',
        first_name: 'A',
        last_name: 'B',
        email: 'you@email.com',
        password: 'P@ssw0rd!',
        password_confirmation: 'P@ssw0rd!',
        organization: Organization.first
    )
    data = { email: "me@email.com" }
    put "/users/#{user1.id}", data, @headers
    assert response.status == 200
    user_resp = JSON.parse(response.body)
    user1.email = "me@email.com"
    assert_json_user(user_resp,user1)
  end
end
