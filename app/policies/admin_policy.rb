# frozen_string_literal: true

class AdminPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    admin?
  end

  def oauth_status?
    admin?
  end

  def system_health?
    super_admin? || treasury_admin?
  end

  def export_oauth_data?
    super_admin? || treasury_admin?
  end

  def user_management?
    super_admin?
  end

  def role_management?
    super_admin?
  end

  def system_configuration?
    super_admin?
  end

  def view_sensitive_data?
    super_admin? || treasury_admin?
  end

  def bulk_operations?
    super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      case
      when super_admin?
        scope.all
      when treasury_admin?
        # Treasury admins get filtered view of sensitive operations
        scope.where(sensitive: false)
      when chapter_admin?
        # Chapter admins see limited admin functions
        scope.where(chapter_accessible: true)
      else
        scope.none
      end
    end

    private

    def treasury_admin?
      user_present? && user.has_role?(:treasury_team_admin)
    end

    def chapter_admin?
      user_present? && user.has_role?(:country_chapter_admin)
    end
  end
end
