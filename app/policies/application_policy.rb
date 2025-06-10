# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user_present?
  end

  def show?
    user_present?
  end

  def create?
    user_present?
  end

  def new?
    create?
  end

  def update?
    user_present?
  end

  def edit?
    update?
  end

  def destroy?
    admin?
  end

  protected

  def user_present?
    user&.persisted?
  end

  def admin?
    user_present? && user.admin?
  end

  def system_administrator?
    user&.has_role?(:system_administrator)
  end

  def treasury_admin?
    user_present? && user.has_role?(:treasury_team_admin)
  end

  def chapter_admin?
    user_present? && user.has_role?(:country_chapter_admin)
  end

  def submitter?
    user_present? && user.has_role?(:submitter)
  end

  def viewer?
    user_present? && user.has_role?(:viewer)
  end

  def can_approve?
    user_present? && user.can_approve?
  end

  def can_process_payments?
    user_present? && user.can_process_payments?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user&.persisted?
        scope.all
      else
        scope.none
      end
    end

    protected

    def user_present?
      user&.persisted?
    end

    def admin?
      user_present? && user.admin?
    end

    def system_administrator?
      user_present? && user.has_role?(:system_administrator)
    end

    private

    attr_reader :user, :scope
  end
end
