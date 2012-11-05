class Ability
  include CanCan::Ability

  def initialize(user)
    # Static pages available to all visitors
    can :view, [:index, :resumes, :contact]

    return unless user # anonymous

    # All users can view resumes and update their credentials
    can :read, Resume
    can :read, User, id: user.id
    can :update, User, id: user.id

    if user.student?
      # Students can create and manage their own resumes
      can :create, Resume
      can :manage, Resume, user_id: user.id

      can [:view, :index, :create], :files
    end

    if user.admin?
      can :manage, :all
    end
  end
end
