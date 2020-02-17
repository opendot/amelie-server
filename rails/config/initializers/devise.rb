Devise.setup do |config|
  
    # ==> Mailer Configuration
    # Configure the e-mail address which will be shown in Devise::Mailer,
    # note that it will be overwritten if you use your own mailer class
    # with default "from" parameter.
    config.mailer_sender = "no-reply@amelie.me"
  
    # The secret key used by Devise. Devise uses this key to generate
    # random tokens. Changing this key will render invalid all existing
    # confirmation, reset password and unlock tokens in the database.
    # Devise will use the `secret_key_base` as its `secret_key`
    # by default. You can change it below and use your own secret key.
    config.secret_key = ENV[ 'DEVISE_TOKEN_AUTH_SECRET_KEY' ]
  
    # If using rails-api, you may want to tell devise to not use ActionDispatch::Flash
    # middleware b/c rails-api does not include it.
    # See: http://stackoverflow.com/q/19600905/806956
    config.navigational_formats = [:json]
  
    # Configure which authentication keys should be case-insensitive.
    # These keys will be downcased upon creating or modifying a user and when used
    # to authenticate or find a user. Default is :email.
    config.case_insensitive_keys = [:email]
  
    # Configure which authentication keys should have whitespace stripped.
    # These keys will have whitespace before and after removed upon creating or
    # modifying a user and when used to authenticate or find a user. Default is :email.
    config.strip_whitespace_keys = [:email]
  
    # Set up a pepper to generate the hashed password.
    config.pepper = ENV[ 'DEVISE_TOKEN_AUTH_PEPPER' ]
  
    # Send a notification email when the user's password is changed
    config.send_password_change_notification = true
  
    # ==> Configuration for :validatable
    # Range for password length.
    config.password_length = 8..60
  
    # Email regex used to validate email formats. It simply asserts that
    # one (and only one) @ exists in the given string. This is mainly
    # to give user feedback and not to assert the e-mail validity.
    config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  
    # ==> Configuration for :lockable
    # Defines which strategy will be used to lock an account.
    # :failed_attempts = Locks an account after a number of failed attempts to sign in.
    # :none            = No lock strategy. You should handle locking by yourself.
    config.lock_strategy = :failed_attempts
  
    # Defines which key will be used when locking and unlocking an account
    config.unlock_keys = [:email]
  
    # Defines which strategy will be used to unlock an account.
    # :email = Sends an unlock link to the user email
    # :time  = Re-enables login after a certain amount of time (see :unlock_in below)
    # :both  = Enables both strategies
    # :none  = No unlock strategy. You should handle unlocking by yourself.
    config.unlock_strategy = :time
  
    # Number of authentication tries before locking an account if lock_strategy
    # is failed attempts.
    config.maximum_attempts = 10
  
    # Time interval to unlock the account if :time is enabled as unlock_strategy.
    config.unlock_in = 10.minutes
  
    # ==> Configuration for :recoverable
    #
    # Defines which key will be used when recovering the password for an account
    config.reset_password_keys = [:email]
  
    # Time interval you can reset your password with a reset password key.
    # Don't put a too small interval or your users won't have the time to
    # change their passwords.
    config.reset_password_within = 12.hours
  
    # When set to false, does not sign a user in automatically after their password is
    # reset. Defaults to true, so a user is signed in automatically after a reset.
    config.sign_in_after_reset_password = false
  
    # ==> Configuration for :encryptable
    # Allow you to use another hashing or encryption algorithm besides bcrypt (default).
    # You can use :sha1, :sha512 or algorithms from others authentication tools as
    # :clearance_sha1, :authlogic_sha512 (then you should set stretches above to 20
    # for default behavior) and :restful_authentication_sha1 (then you should set
    # stretches to 10, and copy REST_AUTH_SITE_KEY to pepper).
    #
    # Require the `devise-encryptable` gem when using anything other than bcrypt
    # config.encryptor = :sha512
    
  end