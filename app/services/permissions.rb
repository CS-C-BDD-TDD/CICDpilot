class Permissions
  def self.can_be_modified_by(user, item)
    return true if User.has_permission(user, 'modify_all_items')
    return false if !User.has_permission(user, 'modify_organization_items')
    return false if !user
    return false if !user.organization
    return false if !item
    return false if !item.created_by_user
    return false if !item.created_by_user.organization
    return user.organization.guid == item.created_by_user.organization.guid
  end

  def self.can_be_deleted_by(user, item)
    return true if User.has_permission(user, 'delete_all_items')
    return false if !User.has_permission(user, 'delete_organization_items')
    return false if !user
    return false if !user.organization
    return false if !item
    return false if !item.created_by_user
    return false if !item.created_by_user.organization
    return user.organization.guid == item.created_by_user.organization.guid
  end
end
