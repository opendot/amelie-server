# Basic configuration for the mailer
class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@amelie.me'
  layout 'mailer'
end