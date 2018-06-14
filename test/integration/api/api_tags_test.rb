require 'test_helper'

class ApiTagsTest < ActionDispatch::IntegrationTest
  def setup
    setup_api_user
    default_permissions
  end

  def teardown
    @headers = nil
  end

  test 'does not show user tags as available tags for two different users' do
    tag = UserTag.create!(name:'red',user_guid:'some-other-guid')
    UserTag.create!(name:'blue',user_guid:@user.guid)
    get("/user_tags.json",nil,@headers)
    jsons = JSON.parse(response.body)
    guids = jsons.map {|json| json['guid']}
    assert !guids.include?(tag.guid)
  end
end
