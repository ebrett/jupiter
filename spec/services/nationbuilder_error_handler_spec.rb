require 'rails_helper'

RSpec.describe NationbuilderErrorHandler do
  let(:user) { build_stubbed(:user, id: 1) }
  let!(:nationbuilder_token) { build_stubbed(:nationbuilder_token, user: user) }
  let(:error_handler) { described_class.new(user: user) }

  # Optimize by stubbing expensive service initializations
  let(:mock_access_monitor) { double("AccessMonitor") }
  let(:mock_notification_service) { double("NotificationService") }
  let(:mock_graceful_degradation) { double("GracefulDegradation") }
  let(:mock_audit_logger) { double("AuditLogger") }

  before do
    # Stub service class initializations
    allow(NationbuilderAccessMonitor).to receive(:new).and_return(mock_access_monitor)
    allow(NationbuilderNotificationService).to receive(:new).and_return(mock_notification_service)
    allow(NationbuilderGracefulDegradation).to receive(:new).and_return(mock_graceful_degradation)
    allow(NationbuilderAuditLogger).to receive(:new).and_return(mock_audit_logger)

    # Stub all expected method calls with default responses
    allow(mock_access_monitor).to receive_messages(detect_revocation_from_error: false, handle_access_revocation: true, global_revocation_detected?: false)

    allow(mock_notification_service).to receive_messages(notify_user: { success: true }, send_reauthentication_prompt: { success: true })

    allow(mock_graceful_degradation).to receive_messages(current_feature_level: :readonly, feature_status_summary: {
      features: { data_sync: { available: true } }
    }, generate_degradation_message: "Service temporarily limited", suggest_recovery_action: "retry_later")

    allow(mock_audit_logger).to receive(:log_event)
    allow(mock_audit_logger).to receive(:log_authentication_event)
  end

  describe '#initialize' do
    it 'initializes all required services' do
      expect(error_handler.user).to eq(user)
      expect(error_handler.access_monitor).to be_present
      expect(error_handler.notification_service).to be_present
      expect(error_handler.graceful_degradation).to be_present
      expect(error_handler.audit_logger).to be_present
    end
  end

  describe '#handle_error' do
    let(:error) { NationbuilderOauthErrors::InvalidAccessTokenError.new("Token expired") }

    it 'logs the error and returns recovery strategy' do
      result = error_handler.handle_error(error)

      expect(result).to have_key(:strategy)
      expect(result).to have_key(:action_taken)
    end

    context 'with access revocation error' do
      let(:error) { NationbuilderOauthErrors::AccessRevokedError.new("Access revoked") }

      it 'handles access revocation specifically' do
        # Override default stub for this specific test
        allow(mock_access_monitor).to receive(:detect_revocation_from_error).with(error).and_return(true)

        result = error_handler.handle_error(error)

        expect(result[:strategy]).to eq(:access_revoked)
        expect(result[:action_taken]).to eq(:tokens_revoked)
      end
    end

    context 'with token refresh error' do
      let(:error) { NationbuilderOauthErrors::InvalidAccessTokenError.new("Token invalid") }

      it 'attempts token refresh' do
        # Mock the token relationship to return our token
        token_relation = double('token_relation')
        allow(token_relation).to receive_messages(order: token_relation, first: nationbuilder_token)
        allow(user).to receive(:nationbuilder_tokens).and_return(token_relation)
        allow(nationbuilder_token).to receive(:refresh!).and_return(true)

        result = error_handler.handle_error(error)

        expect(result[:strategy]).to eq(:token_refresh)
        expect(result[:success]).to be true
      end
    end
  end

  describe '#handle_reauthentication_required' do
    let(:error) { NationbuilderOauthErrors::InvalidRefreshTokenError.new("Refresh token expired") }

    it 'invalidates tokens and creates notifications' do
      result = error_handler.handle_reauthentication_required(error)

      expect(result[:strategy]).to eq(:reauthentication_required)
      expect(result[:requires_user_action]).to be true
    end
  end

  describe '#handle_unrecoverable_error' do
    let(:error) { NationbuilderOauthErrors::NetworkError.new("Network timeout") }

    context 'when graceful degradation is available' do
      it 'provides degraded service' do
        result = error_handler.handle_unrecoverable_error(error)

        expect(result[:strategy]).to eq(:graceful_degradation)
        expect(result[:degraded_response][:available]).to be true
      end
    end

    context 'when no degradation is available' do
      it 'logs and fails gracefully' do
        # Override default stub for this specific test
        allow(mock_graceful_degradation).to receive(:current_feature_level).and_return(:none)

        result = error_handler.handle_unrecoverable_error(error)

        expect(result[:strategy]).to eq(:log_and_fail)
      end
    end
  end
end
