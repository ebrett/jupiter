class AuthModalComponent < ViewComponent::Base
  include FeatureFlagHelper

  def initialize(mode: :login)
    @mode = mode.to_sym
  end

  def current_user
    Current.user
  end

  # Override feature_enabled? to handle global features for unauthenticated users
  def feature_enabled?(flag_name)
    FeatureFlagService.enabled?(flag_name, current_user)
  end

  private

  attr_reader :mode

  def login_mode?
    mode == :login
  end

  def register_mode?
    mode == :register
  end

  def modal_title
    login_mode? ? "Sign in to Jupiter" : "Create your Jupiter account"
  end

  def switch_mode_text
    login_mode? ? "Don't have an account?" : "Already have an account?"
  end

  def switch_mode_link
    login_mode? ? "Sign up" : "Sign in"
  end

  def switch_mode_action
    login_mode? ? "auth#switchToRegister" : "auth#switchToLogin"
  end

  def primary_button_text
    login_mode? ? "Sign in" : "Create account"
  end

  def nationbuilder_button_text
    nation_name = nation_display_name
    login_mode? ? "Sign In with #{nation_name}" : "Sign Up with #{nation_name}"
  end

  def form_path
    login_mode? ? session_path : users_path
  end

  private

  def nation_display_name
    slug = ENV["NATIONBUILDER_NATION_SLUG"]
    return "NationBuilder" if slug.blank?

    # Convert slug to display name (e.g., "democrats-abroad" -> "Democrats Abroad")
    slug.split("-").map(&:capitalize).join(" ")
  end
end
