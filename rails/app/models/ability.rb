class Ability
  include CanCan::Ability
  # Handle permissions to API requests based on User type

  def initialize(user)
    server_local = Rails.env.ends_with?("local") || (Rails.env.test? && ENV["TEST_ROUTES"] == "local")

    if user.is_guest?
      # GuestUsers can only use the offline server with the Communication
      if server_local
        can :manage, AudioFile
        can :manage, CardTag
        can :manage, Card
        cannot :manage, CognitiveCard
        can :manage, CommunicationSession
        can :manage, PageTag
        can :manage, Page
        can :manage, Patient
        can :manage, PreviewTree
        can :manage, SessionEvent
        can :manage, TrackerCalibrationParameter
        can [:align_eyetracker, :change_route], TrainingSession
        can :manage, Tree
      else
        cannot :manage, :all
      end
    elsif user.is_a? DesktopPc
      # DesktopPc can only use the offline server
      if server_local
        can [:create, :update], AudioFile
        can :read, Card
        can :read, Page
        # can :manage, Patient
        # can :manage, PreviewTree
        can :create, SessionEvent
        can [:read, :update], TrackerCalibrationParameter
        can :create, TrackerRawDatum
        can :read, TrainingSession
        can :read, Tree
      else
        cannot :manage, :all
      end
    else
      can :manage, :all
      if server_local
        cannot :manage, Package
        cannot [:create, :update, :destroy], Patient
        cannot [:index, :disable], User
      else
        if user.is_a?(Superadmin) || user.is_a?(Researcher)
          can :manage, Package
        else
          cannot :manage, Package
        end

        case user
        when Parent
          can :manage, Patient
          cannot :disable, User
        when Researcher
          cannot [:create, :update, :destroy], Patient
          cannot [:index, :disable], User
        when Superadmin
          can :manage, Patient
          can :disable, User
        when Therapist
          cannot [:create, :update, :destroy], Patient
          cannot [:index, :disable], User
        end
      end
    end
  end
end
