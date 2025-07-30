class VendorRequestPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def new?
    user.can_submit_requests?
  end

  def create?
    user.can_submit_requests?
  end

  def edit?
    false # No editing in Phase 1
  end

  def update?
    false # No editing in Phase 1
  end

  def destroy?
    false # No deletion in Phase 1
  end

  def export?
    user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
