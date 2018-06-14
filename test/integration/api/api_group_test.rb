require 'test_helper'

class ApiGroupTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test "list groups" do
    current_count = Group.count
    group1 = Group.create!(name: 'first', description: 'a')
    group2 = Group.create!(name: 'second', description: 'b')
    perm = Permission.find_by_name('create_modify_user_organization')
    GroupPermission.create!(group: group1, permission: perm)

    get("/groups.json",nil,@headers)
    result = JSON.parse(response.body)
    group_resp = result[(current_count+1)-1]

    assert_json_group(group_resp,group1)
    assert_json_group(result[(current_count+2)-1],group2)
  end

  test "create group" do
    current_count = Group.count
    g = Group.create(name:'People',description:'test')
    p = Permission.find_by_name('create_modify_user_organization')
    g.permissions << p
    User.first.groups << g
    data = {name: 'new', description: 'test' }
    post "/groups", data, @headers
    assert response.status == 200
    assert Group.count == current_count+2
    assert_json_group(JSON.parse(response.body),Group.last)
  end
end
