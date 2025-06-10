# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    system_administrator?
  end

  def show?
    system_administrator? || own_record?
  end

  def create?
    system_administrator?
  end

  # Only system administrators can update users (cannot update self or other system administrators).
  # This may be expanded to other admin roles (e.g., treasury/chapter/country committee admins) in the future.
  def update?
    system_administrator? && !own_record? && !target_is_system_administrator?
  end

  def destroy?
    system_administrator? && !own_record? && !target_is_system_administrator?
  end

  def manage_roles?
    system_administrator?
  end

  def assign_role?
    system_administrator?
  end

  def remove_role?
    system_administrator?
  end

  def bulk_update?
    system_administrator?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      case
      when system_administrator?
        scope.all
      when admin?
        # Admins can see all users except system admins
        scope.joins(:roles).where.not(roles: { name: "system_administrator" }).distinct
      else
        # Regular users can only see themselves
        scope.where(id: user.id)
      end
    end
  end

  private

  def own_record?
    record == user
  end

  def target_is_system_administrator?
    record&.has_role?(:system_administrator)
  end

  def system_administrator?
    user&.has_role?(:system_administrator)
  end
end
