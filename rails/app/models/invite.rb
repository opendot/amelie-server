class Invite < ApplicationRecord
  belongs_to :user
  validates :mail, format: { with: URI::MailTo::EMAIL_REGEXP }
end
