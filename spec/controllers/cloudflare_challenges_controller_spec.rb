require 'rails_helper'

RSpec.describe CloudflareChallengesController, type: :controller do
  let(:session_id) { SecureRandom.hex(32) }
  let(:valid_challenge) do
    create(:cloudflare_challenge,
           challenge_id: challenge_id,
           challenge_type: 'turnstile',
           challenge_data: { 'turnstile_present' => true },
           oauth_state: 'test-oauth-state',
           session_id: session_id,
           expires_at: 15.minutes.from_now)
  end
  let(:challenge_id) { SecureRandom.uuid }

  # Override the session.id method to return our test session ID
  before do
    allow(session).to receive(:id).and_return(session_id)

    # Enable cloudflare challenge handling feature flag for tests
    @cloudflare_flag = FeatureFlag.find_or_create_by!(name: 'cloudflare_challenge_handling') do |flag|
      flag.description = 'Test flag for Cloudflare challenge handling'
      flag.enabled = true
    end
  end


  describe 'GET #show' do
    context 'with valid turnstile challenge' do
      before { valid_challenge }

      it 'renders the challenge page' do
        get :show, params: { challenge_id: challenge_id }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
      end

      it 'assigns challenge data' do
        get :show, params: { challenge_id: challenge_id }

        expect(assigns(:challenge_data)).to eq(valid_challenge.challenge_data)
        expect(assigns(:site_key)).to eq(CloudflareConfig.turnstile_site_key)
        expect(assigns(:callback_url)).to eq(verify_cloudflare_challenge_url(challenge_id))
      end
    end

    context 'with browser challenge' do
      let(:browser_challenge) do
        create(:cloudflare_challenge,
               challenge_id: challenge_id,
               challenge_type: 'browser_challenge',
               challenge_data: { 'challenge_stage_present' => true },
               oauth_state: 'test-oauth-state',
               session_id: session_id,
               expires_at: 15.minutes.from_now)
      end

      before { browser_challenge }

      it 'renders the challenge page with manual instructions' do
        get :show, params: { challenge_id: challenge_id }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
      end

      it 'assigns challenge data for manual verification' do
        get :show, params: { challenge_id: challenge_id }

        expect(assigns(:challenge_data)).to eq(browser_challenge.challenge_data)
        expect(assigns(:site_key)).to eq(CloudflareConfig.turnstile_site_key)
        expect(assigns(:callback_url)).to eq(verify_cloudflare_challenge_url(challenge_id))
      end
    end

    context 'with expired challenge' do
      let(:expired_challenge) do
        create(:cloudflare_challenge,
               challenge_id: challenge_id,
               expires_at: 1.hour.ago,
               session_id: session_id)
      end

      before { expired_challenge }

      it 'redirects to sign in with error' do
        get :show, params: { challenge_id: challenge_id }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to include('Challenge has expired')
      end
    end

    context 'with non-existent challenge' do
      it 'redirects to sign in with error' do
        get :show, params: { challenge_id: 'non-existent-id' }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to include('Challenge not found')
      end
    end

    context 'with wrong session' do
      let(:wrong_session_challenge) do
        create(:cloudflare_challenge,
               challenge_id: challenge_id,
               session_id: 'different-session-id')
      end

      before { wrong_session_challenge }

      it 'redirects to sign in with error' do
        get :show, params: { challenge_id: challenge_id }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to include('Challenge not found')
      end
    end
  end

  describe 'POST #verify' do
    let(:turnstile_response) { 'test-turnstile-response-token' }
    let(:verification_service) { instance_double(TurnstileVerificationService) }

    before do
      valid_challenge
      allow(TurnstileVerificationService).to receive(:new).and_return(verification_service)
    end

    context 'with successful verification' do
      before do
        allow(verification_service).to receive(:verify).and_return(true)
      end

      it 'redirects to complete path' do
        post :verify, params: {
          challenge_id: challenge_id,
          cf_turnstile_response: turnstile_response
        }

        expect(response).to redirect_to(complete_cloudflare_challenge_path(challenge_id))
      end

      it 'stores completion in session' do
        post :verify, params: {
          challenge_id: challenge_id,
          cf_turnstile_response: turnstile_response
        }

        expect(session[:completed_challenge_id]).to eq(challenge_id)
      end

      it 'creates verification service with correct params' do
        expect(TurnstileVerificationService).to receive(:new).with(
          response_token: turnstile_response,
          user_ip: request.remote_ip
        ).and_return(verification_service)

        post :verify, params: {
          challenge_id: challenge_id,
          cf_turnstile_response: turnstile_response
        }
      end
    end

    context 'with failed verification' do
      before do
        allow(verification_service).to receive(:verify).and_return(false)
      end

      it 'renders show template with error' do
        post :verify, params: {
          challenge_id: challenge_id,
          cf_turnstile_response: turnstile_response
        }

        expect(response).to render_template(:show)
        expect(flash.now[:alert]).to include('Challenge verification failed')
      end

      it 'reassigns challenge data' do
        post :verify, params: {
          challenge_id: challenge_id,
          cf_turnstile_response: turnstile_response
        }

        expect(assigns(:challenge_data)).to eq(valid_challenge.challenge_data)
        expect(assigns(:site_key)).to eq(CloudflareConfig.turnstile_site_key)
      end
    end

    context 'with missing turnstile response' do
      it 'renders show template with error' do
        post :verify, params: { challenge_id: challenge_id }

        expect(response).to render_template(:show)
        expect(flash.now[:alert]).to include('Please complete the challenge')
      end
    end

    context 'with browser challenge manual verification' do
      let(:browser_challenge_id) { SecureRandom.uuid }
      let(:browser_challenge) do
        create(:cloudflare_challenge,
               challenge_id: browser_challenge_id,
               challenge_type: 'browser_challenge',
               challenge_data: { 'challenge_stage_present' => true },
               oauth_state: 'test-oauth-state',
               session_id: session_id,
               expires_at: 15.minutes.from_now)
      end

      before { browser_challenge }

      it 'completes manual verification without turnstile token' do
        post :verify, params: { challenge_id: browser_challenge_id }

        expect(response).to redirect_to(complete_cloudflare_challenge_path(browser_challenge_id))
        expect(session[:completed_challenge_id]).to eq(browser_challenge_id)
      end

      it 'updates challenge with manual verification timestamp' do
        expect {
          post :verify, params: { challenge_id: browser_challenge_id }
        }.to change { browser_challenge.reload.updated_at }
      end

      it 'does not call TurnstileVerificationService' do
        expect(TurnstileVerificationService).not_to receive(:new)
        post :verify, params: { challenge_id: browser_challenge_id }
      end
    end

    context 'with expired challenge' do
      before do
        valid_challenge.update!(expires_at: 1.hour.ago)
      end

      it 'redirects to sign in with error' do
        post :verify, params: {
          challenge_id: challenge_id,
          cf_turnstile_response: turnstile_response
        }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to include('Challenge has expired')
      end
    end
  end

  describe 'GET #complete' do
    before { valid_challenge }

    context 'with completed challenge in session' do
      before do
        session[:completed_challenge_id] = challenge_id
      end

      it 'redirects to OAuth callback with completion flag' do
        get :complete, params: { challenge_id: challenge_id }

        expected_url = "/auth/nationbuilder/callback?#{valid_challenge.original_params.to_query}&challenge_completed=true"
        expect(response).to redirect_to(expected_url)
      end

      it 'clears completed challenge from session' do
        get :complete, params: { challenge_id: challenge_id }

        expect(session[:completed_challenge_id]).to be_nil
      end

      it 'does not destroy challenge immediately' do
        expect {
          get :complete, params: { challenge_id: challenge_id }
        }.not_to change(CloudflareChallenge, :count)
      end
    end

    context 'without completed challenge in session' do
      it 'redirects to sign in with error' do
        get :complete, params: { challenge_id: challenge_id }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to include('Challenge not completed')
      end
    end

    context 'with mismatched challenge ID' do
      before do
        session[:completed_challenge_id] = 'different-challenge-id'
      end

      it 'redirects to sign in with error' do
        get :complete, params: { challenge_id: challenge_id }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to include('Challenge mismatch')
      end
    end
  end

  describe 'before_actions' do
    context 'unauthenticated access' do
      it 'allows access to show action' do
        valid_challenge
        get :show, params: { challenge_id: challenge_id }

        expect(response).not_to redirect_to(sign_in_path)
      end

      it 'allows access to verify action' do
        valid_challenge
        post :verify, params: { challenge_id: challenge_id }

        expect(response).not_to be_redirect
      end

      it 'allows access to complete action' do
        valid_challenge
        get :complete, params: { challenge_id: challenge_id }

        # It will redirect due to missing session data, not authentication
        expect(flash[:alert]).not_to include('sign in')
      end
    end
  end
end
