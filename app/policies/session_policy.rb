# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def show?
    own_session? || admin?
  end

  def create?
    true # Anyone can create a session (login)
  end

  def destroy?
    own_session? || admin?
  end

  def index?
    admin?
  end

  def manage_others?
    super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      case
      when super_admin?
        scope.all
      when admin?
        # Admins can see sessions but not super admin sessions
        scope.joins(:user).where.not(users: { id: super_admin_user_ids })
      else
        # Users can only see their own sessions
        scope.where(user: user)
      end
    end

    private

    def super_admin_user_ids
      User.joins(:roles).where(roles: { name: "super_admin" }).pluck(:id)
    end
  end

  private

  def own_session?
    record&.user == user
  end
end
