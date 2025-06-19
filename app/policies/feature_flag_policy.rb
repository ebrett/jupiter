class FeatureFlagPolicy < ApplicationPolicy
  def index?
    user&.admin?
  end

  def show?
    user&.admin?
  end

  def new?
    user&.admin? && user&.has_role?(:system_administrator)
  end

  def create?
    user&.admin? && user&.has_role?(:system_administrator)
  end

  def edit?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def toggle?
    user&.admin?
  end

  def destroy?
    user&.admin? && user&.has_role?(:system_administrator)
  end

  def clear_cache?
    user&.admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
