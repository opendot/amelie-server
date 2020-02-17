# The class used to authenticate application's users
# name: string
# surname: string
# birthdate: datetime
# type: string          used for Single Table Inheritance and abilities of Cancancan
# organization: string  organization the user is part of, used for researchers
# role: string          role of the user in the organization, used for researchers
# description: text     description of the user of the research he works on, used for researchers
class User < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :recoverable, :timeoutable, :trackable, :validatable, :lockable, :registerable
  include DeviseTokenAuth::Concerns::User

  before_save :check_tokens_count

  has_many :trees, through: :user_trees
  has_many :user_trees
  has_many :notices
  has_many :invites

  has_and_belongs_to_many :patients, before_add: :limit_users_for_patient

  validates :name, :surname, :email, :type, presence: true

  validates :type, inclusion: { in: %w(Parent Therapist Researcher Superadmin Teacher DesktopPc GuestUser), message: "%{value} #{I18n.t :error_user_type}" }

  # Creation order is the default one.
  default_scope { order(:created_at) }
  scope :not_guest, -> {where.not(type: %w(GuestUser))}

  def limit_users_for_patient(patient)
    if self.is_a? Parent
      if patient.users.where(type: "Parent").limit(1).count > 0
        raise ActiveRecord::Rollback
      end
    end
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def check_tokens_count
    return if self.tokens.nil?
    while self.tokens.keys.length > 0 && ENV["DEVISE_TOKEN_AUTH_MAX_CLIENTS_COUNT"].to_i < self.tokens.keys.length
      oldest_token = self.tokens.min_by { |cid, v| v[:expiry] || v["expiry"] }
      self.tokens.delete(oldest_token.first)
    end
  end

  def add_patient(patient)
    self.patients << patient unless self.patients.include?(patient)
  end

  def is_guest?
    %w(GuestUser).include? self.type
  end

  def can_access_all_patients?
    %w(Researcher Superadmin).include? self.type
  end

  def can_access_all_anonymized_patients?
    %w(Researcher).include? self.type
  end

  def show_anonymized_patient? patient_id
    self.can_access_all_anonymized_patients? && !self.patients.exists?(patient_id)
  end

  def disabled?
    if self.is_a? Parent
      return self.patients.where(disabled: true).limit(1).count > 0
    else
      return false
    end
  end

  def set_disabled disabled
    self.patients.update_all(disabled: disabled)
  end

end
