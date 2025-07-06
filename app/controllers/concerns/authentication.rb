module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie

      # Check if session is expired
      if Current.session&.expired?
        terminate_session
        Current.session = nil
        Current.user = nil
        return nil
      end

      Current.user ||= Current.session&.user
      Current.session
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      # Don't store authentication-related URLs as return destinations
      unless request.path.start_with?("/session") || request.path.start_with?("/auth") || request.path.start_with?("/sign-")
        session[:return_to_after_authenticating] = request.url
      end
      redirect_to sign_in_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user, remember_me: false)
      user.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip,
        remember_me: remember_me
      ).tap do |session|
        Current.session = session

        # Set cookie duration based on remember_me preference
        if remember_me
          cookies.signed[:session_id] = {
            value: session.id,
            expires: Session::REMEMBER_ME_DURATION.from_now,
            httponly: true,
            same_site: :lax
          }
        else
          cookies.signed[:session_id] = {
            value: session.id,
            expires: Session::DEFAULT_SESSION_DURATION.from_now,
            httponly: true,
            same_site: :lax
          }
        end

        # Trigger NationBuilder profile sync if applicable
        if user.nationbuilder_user?
          NationbuilderProfileSyncJob.perform_later(user.id)
        end
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
