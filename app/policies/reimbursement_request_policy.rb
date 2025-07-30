# frozen_string_literal: true

class ReimbursementRequestPolicy < ApplicationPolicy
  def index?
    user_present?
  end

  def show?
    return false unless user_present?

    owns_record? || admin?
  end

  def create?
    return false unless user_present?

    user.can_submit_requests?
  end

  def update?
    return false unless user_present?

    # Admins can always update
    return true if admin?

    # Owners can only update their own draft requests
    owns_record? && record.draft?
  end

  def destroy?
    return false unless user_present?

    # System administrators can delete any request
    return true if system_administrator?

    # Owners can only delete their own draft requests
    owns_record? && record.draft?
  end

  def submit?
    return false unless user_present?

    owns_record? && record.draft?
  end

  def export?
    admin?
  end

  # Admin-specific actions
  def admin_access?
    admin?
  end

  def approve?
    admin?
  end

  def reject?
    admin?
  end

  def request_info?
    admin?
  end

  def mark_paid?
    admin?
  end

  def bulk_approve?
    admin?
  end

  def permitted_attributes
    permitted_attributes_for_create
  end

  def permitted_attributes_for_create
    [
      :title, :description, :amount_in_dollars, :currency, :expense_date,
      :category, :priority, receipts: []
    ]
  end

  def permitted_attributes_for_update
    # If request is submitted, only allow receipts to be updated
    if record&.submitted? || record&.under_review? || record&.approved? || record&.rejected?
      [ :receipts ]
    else
      # For draft requests, allow all creation attributes
      permitted_attributes_for_create
    end
  end

  private

  def owns_record?
    record&.user_id == user&.id
  end

  class Scope < Scope
    def resolve
      return scope.none unless user_present?

      # Admins can see all requests
      return scope.all if admin?

      # Regular users can only see their own requests
      scope.where(user: user)
    end

    private

    def user_present?
      user&.persisted?
    end

    def admin?
      user_present? && user.admin?
    end
  end
end
