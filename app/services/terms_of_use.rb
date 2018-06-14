class TermsOfUse

  def initialize(user)
    @user = user
  end

  def accepted?
    @user.terms_accepted_at?
  end

  def can_login?
    @user.terms_accepted_at?
  end

  def accept_terms!
   @user.terms_accepted_at = Time.now
   @user.save
  end

end
