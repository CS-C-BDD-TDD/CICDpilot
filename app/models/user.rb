class User < ActiveRecord::Base
  belongs_to  :organization, primary_key: :guid, foreign_key: :organization_guid
  has_many    :user_groups, primary_key: :guid, foreign_key: :user_guid
  has_many    :groups, through: :user_groups, before_remove: :audit_group_removal
  has_many    :permissions, -> { uniq }, through: :groups
  has_many    :uploaded_files, primary_key: :guid, foreign_key: :user_guid
  has_one     :isa_entity_cache, primary_key: :guid, foreign_key: :user_guid
  has_many    :passwords, -> {order(created_at: :desc)}, primary_key: :guid, foreign_key: :user_guid, before_add: :discard_old_password
  has_many    :tags
              

  before_save :prepare_password
  before_create { self.is_new_user = self.new_record? }
  after_save :store_password

  attr_accessor :password, :is_new_user, :password_confirmation, :old_password

  validates_presence_of     :username, :first_name, :last_name, :email
  validate :has_organization
  def has_organization
    errors.add(:organization, "You must set an organization for the user") if !organization_guid
  end

  unless (Setting.SSO_AD)
    # We do not need to validate the presense of a password
    validates_confirmation_of :password
    validates_presence_of :password,:password_confirmation, on: :create
    validates_presence_of :password_confirmation, if: :password_changed?
  end

  validate                  :unique_username_sid
  def unique_username_sid
    users = User.where(username: self.username)
    users.each do |u|
      next if u.id == self.id # skip ourselves
      #TODO: if SID doesn't match, this is OK
      if self.disabled_at.blank? && u.disabled_at.blank?
        errors.add(:username, "is already taken by another user")
        return false
      end
    end
    return true
  end

  validates_format_of       :username,
    :with => /\A[-\w\._@]+\z/i,
    :allow_blank => true,
    :message => "should only contain letters, numbers, or .-_@"
  validates_format_of       :email,
    :with => /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\z/i,
    :allow_blank => true,
    :allow_nil => true
  validates_format_of       :password,
                            :with => /\A.*(?=.*[a-z])(?=.*[A-Z])(?=.*[\d])(?=.*[\W]).*\z/,
                            :message => "must contain at least one lower-case letter, one upper-case letter, one number, and one symbol.",
                            :allow_blank => true

  validates_length_of       :password, :minimum => 14, :allow_blank => true if Rails.env == 'production'

  validate                  :password_does_not_contain_username
  validate                  :is_new_password
  validate                  :old_password_match

  accepts_nested_attributes_for :isa_entity_cache

  def password_does_not_contain_username
    unless password.blank? || username.blank?
      if password.include? username
        errors.add( :password, "Password can not include your username." )
      end
    end
  end

  def generate_api_key
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets[:secret_key_base])
    self.api_key = Digest::SHA256.hexdigest( BCrypt::Engine.generate_salt )
    return self.save
  end

  def revoke_api_key
    self.api_key = nil
    return self.save
  end

  def change_api_key_secret(secret)
    return false if secret.blank? # can't set a nil or blank secret
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets[:secret_key_base])
    encrypted_secret = crypt.encrypt_and_sign(secret)
    return self.update_column(:api_key_secret_encrypted, encrypted_secret)
  end

  def enable_disable
    if self.disabled_at.present? || self.expired_at.present?
      self.disabled_at = nil
      self.expired_at = nil
      self.logged_in_at = nil
      if self.save
        audit = Audit.basic
        audit.message = "User account enabled - '#{self.username}'"
        audit.audit_type = :user
        audit.item = self
        self.audits << audit
        return true
      end
    else
      self.disabled_at = Time.now
      if self.save
        audit = Audit.basic
        audit.message = "User account disabled - '#{self.username}'"
        audit.audit_type = :user
        audit.item = self
        self.audits << audit
        return true
      end
    end
    return false
  end

  def self.current_user
    Thread.current[:current_user]
  end

  def self.current_user=(user)
    Thread.current[:current_user] = user
  end

  def self.has_permission(user,perm)
    return false unless user.present?
    permissions=user.permissions
    (permissions.index { |x| x.name == perm.to_s }).nil? ? false : true
  end

  def correct_password?(password)
    # if no password is set, no password_salt is set.  If no password_salt is set, encrypt_password breaks
    return false if !self.password_salt
    password_hash == encrypt_password(password)
  end

  def expired?
    return true if self.expired_at.present?
    if self.logged_in_at.present? && self.logged_in_at < 30.days.ago
      self.update_column(:expired_at,self.logged_in_at+30.days)
      AuthenticationLogger.info("[expired] username: #{self.username} is now expired")
      Logging::AuthenticationLog.create(
          info: "[expired] username: #{self.username} is now expired",
          event: 'expired',
          user: self
      )
      return true
    end
    false
  end

  include Auditable
  include Guidable
  include Serialized
  include Transferable
  
  def audit_update
    # return if no changes to indicator directly
    return if self.changes.except("updated_at").length == 0
    audit = Audit.basic(self,self)

    clazz = self.class if self.class
    model_name = clazz.model_name if clazz
    class_name = model_name.human if model_name

    audit.message = "Updated #{class_name}"
    sanitized_changes = Auditable.sanitize_changes(self.changes, self.class)
    audit.details = sanitized_changes.to_s
    audit.audit_type = :update
    self.audits << audit
    return
  end

  after_save :audit_organization_change
  def audit_organization_change
    if (self.changes.include?("organization_guid"))
      if self.changes["organization_guid"][1].nil?
        # Removed from organization
        audit = Audit.basic
        organization = Organization.find_by_guid(self.changes["organization_guid"][0])
        audit.message = "User '#{self.username}' removed from organization '#{organization.short_name} - #{organization.long_name}'"
        audit.audit_type = :organization
        user_audit = audit.dup
        user_audit.item = self
        self.audits << user_audit
        org_audit = audit.dup
        org_audit.item = organization
        organization.audits << org_audit
        return
      else
        # added to organization
        audit = Audit.basic
        organization = Organization.find_by_guid(self.changes["organization_guid"][1])
        audit.message = "User '#{self.username}' added to organization '#{organization.short_name} - #{organization.long_name}'"
        audit.audit_type = :organization
        user_audit = audit.dup
        user_audit.item = self
        self.audits << user_audit
        org_audit = audit.dup
        org_audit.item = organization
        organization.audits << org_audit
        return
      end
    end
  end

  private

  def old_password_match
    if current_user_is_admin? && User.current_user.username == self.username
      unless self.changed? || (self.old_password && correct_password?(self.old_password))
        errors.add(:old_password, "Incorrect Old Password")
      end
    end
  end

  def prepare_password
    unless password.blank?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = encrypt_password(password)
    end
  end

  def encrypt_password(password)
    return "DOES_NOT_ENCRYPT" if !password_salt
    BCrypt::Engine.hash_secret(password,password_salt)
  end

  def current_user_is_admin?
    User.has_permission(User.current_user, 'view_user_organization')
  end

  def is_new_password
    if self.machine?
      self.password = nil
      return
    end
    return unless password.present?
    latest_password = self.passwords.reorder(created_at: :desc).first
    if latest_password && latest_password.incubated?
      # 24 hour restriction only occurs for normal users or admins updating themselves
      if !current_user_is_admin? || (current_user_is_admin? && User.current_user.username == self.username)
        errors.add(:password,"You cannot change your password again for 24 hours")
        return
      end
    end
    self.passwords.each do |passwrd|
      if passwrd.password_hash == BCrypt::Engine.hash_secret(password,passwrd.password_salt)
        errors.add(:password, "You must choose a password different from one you've used before")
        return
      end
    end
  end

  def store_password
    return if self.machine?
    return unless password.present?
    return unless self.valid?
    self.is_new_user = false if self.is_new_user.nil?
    # Password should require change if a) this is a new account, b) an admin changed another user's password
    self.passwords << Password.create(password_hash: self.password_hash, password_salt: self.password_salt, requires_change: self.is_new_user || (current_user_is_admin? && User.current_user.username != self.username))
    if !self.is_new_user && current_user_is_admin? && User.current_user.username != self.username
      Logging::AuthenticationLog.create(
          info: "[password_reset_by_admin] username: #{self.username} has had their password reset",
          event: 'password_reset',
          user: self
      )
    end
    self.old_password = self.password
    self.password = nil
    self.password_confirmation = nil
  end

  def audit_group_removal(item)
    audit = Audit.basic
    audit.message = "User '#{self.username}' removed from group '#{item.name}'"
    audit.audit_type = :ungroup
    group_audit = audit.dup
    group_audit.item = item
    item.audits << group_audit
    user_audit = audit.dup
    user_audit.item = self
    self.audits << user_audit
  end

  def discard_old_password(password)
    prev_passwords = self.passwords
    if prev_passwords.count >= Password::PASSWORD_STORAGE_LIMIT
      prev_passwords.last.destroy
    end
  end

  def password_changed?
    password.present? || self.changes.include?(:password)
  end
end
