class GuestUser < User
  # A user with limited access to the Airett system. It can't synchronize to remote server.
  # A guest only works offline, it must signup in local server.
  # A guest can only access to the communication part of Airett

  def add_patient( patient )
    # Only 1 patient allowed
    if self.patients.count == 0
      super
    else
      raise I18n.t("errors.users.guest_only_one_patient")
    end
  end

end
