class Preference < ApplicationRecord

  def self.get_num_invites
    Preference.first.num_invites
  end

  def self.set_num_invites= val
    Preference.first.update_column(:num_invites, val)
  end

  def self.get_user_expiration_days
    Preference.first.user_expiration_days
  end

  def self.set_user_expiration_days= val
    Preference.first.update_column(:user_expiration_days, val)
  end

  def self.get_invite_text
    Preference.first.user_expiration_days
  end

  def self.set_invite_text= val
    Preference.first.update_column(:invite_text, val)
  end
end
