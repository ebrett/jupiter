# frozen_string_literal: true

class NationbuilderTokenPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    own_token? || admin?
  end

  def create?
    user_present?
  end

  def update?
    own_token? || admin?
  end

  def destroy?
    own_token? || admin?
  end

  def refresh?
    own_token? || admin?
  end

  def manage_others?
    super_admin?
  end

  def view_sensitive_data?
    super_admin? || treasury_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      case
      when super_admin?
        scope.all
      when admin?
        # Admins can see tokens but not super admin tokens
        scope.joins(:user).where.not(users: { id: super_admin_user_ids })
      else
        # Users can only see their own tokens
        scope.where(user: user)
      end
    end

    private

    def super_admin_user_ids
      User.joins(:roles).where(roles: { name: 'super_admin' }).pluck(:id)
    end
  end

  private

  def own_token?
    record&.user == user
  end
end