# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || own_record?
  end

  def create?
    super_admin?
  end

  def update?
    super_admin? || (admin? && !target_is_super_admin?)
  end

  def destroy?
    super_admin? && !own_record? && !target_is_super_admin?
  end

  def manage_roles?
    super_admin?
  end

  def assign_role?
    super_admin?
  end

  def remove_role?
    super_admin?
  end

  def bulk_update?
    super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      case
      when super_admin?
        scope.all
      when admin?
        # Admins can see all users except super admins
        scope.joins(:roles).where.not(roles: { name: "super_admin" }).distinct
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

  def target_is_super_admin?
    record&.has_role?(:super_admin)
  end
end
