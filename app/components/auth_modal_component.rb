class AuthModalComponent < ViewComponent::Base
  def initialize(mode: :login)
    @mode = mode.to_sym
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
    login_mode? ? "Sign in with #{nation_name}" : "Sign up with #{nation_name}"
  end

  private

  def nation_display_name
    slug = ENV["NATIONBUILDER_NATION_SLUG"]
    return "NationBuilder" if slug.blank?

    # Convert slug to display name (e.g., "democrats-abroad" -> "Democrats Abroad")
    slug.split("-").map(&:capitalize).join(" ")
  end
end
