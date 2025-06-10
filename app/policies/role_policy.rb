# frozen_string_literal: true

class RolePolicy < ApplicationPolicy
  def index?
    system_administrator?
  end

  def show?
    system_administrator?
  end

  def create?
    system_administrator?
  end

  def update?
    system_administrator?
  end

  def destroy?
    false # Roles should not be destroyed to maintain data integrity
  end

  def assign_to_user?
    system_administrator?
  end

  def remove_from_user?
    system_administrator?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if system_administrator?
        scope.all
      else
        scope.none
      end
    end
  end
end
