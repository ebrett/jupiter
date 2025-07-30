# frozen_string_literal: true

class Admin::ReimbursementRequestPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def approve?
    return false unless user_present?
    return false unless can_approve?

    # Can approve submitted or under_review requests
    record.submitted? || record.under_review?
  end

  def reject?
    return false unless user_present?
    return false unless can_approve?

    # Can reject submitted or under_review requests
    record.submitted? || record.under_review?
  end

  def request_info?
    return false unless user_present?
    return false unless can_approve?

    # Can request more info only for submitted requests
    record.submitted?
  end

  def mark_paid?
    return false unless user_present?
    return false unless can_process_payments?

    # Can only mark approved requests as paid
    record.approved?
  end

  def update?
    admin?
  end

  def destroy?
    system_administrator?
  end

  def permitted_attributes_for_approve
    [ :approved_amount_cents, :approval_notes ]
  end

  def permitted_attributes_for_reject
    [ :rejection_reason ]
  end

  def permitted_attributes_for_request_info
    [ :notes ]
  end

  class Scope < Scope
    def resolve
      return scope.none unless user_present?
      return scope.none unless admin?

      # All admin types can see all requests
      scope.all
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
