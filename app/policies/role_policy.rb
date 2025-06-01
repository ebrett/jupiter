# frozen_string_literal: true

class RolePolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def create?
    super_admin?
  end

  def update?
    super_admin?
  end

  def destroy?
    false # Roles should not be destroyed to maintain data integrity
  end

  def assign_to_user?
    super_admin?
  end

  def remove_from_user?
    super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
