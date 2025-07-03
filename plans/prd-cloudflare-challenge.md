# PRD: Cloudflare Challenge Handling for NationBuilder OAuth

## Problem Statement

The Jupiter application is experiencing 403 Forbidden errors from Cloudflare when attempting NationBuilder OAuth authentication, preventing deployment of the sign-in feature. The current implementation detects Cloudflare challenges but only displays a generic error message to users, making the OAuth flow unusable in production.

## Current State Analysis

### Existing Code Detection
- `NationbuilderTokenExchangeService:47` detects "Just a moment..." in 403 responses
- `NationbuilderAuthController:43-44` shows static error message for `cloudflare_challenge`
- No mechanism to present actual challenge to users or handle responses

### Problem Impact
- NationBuilder OAuth completely blocked in production
- Users cannot authenticate via NationBuilder
- Deployment of authentication features is impossible
- Generic error messages provide no resolution path

## Solution Overview

Implement a comprehensive Cloudflare challenge handling system that detects challenges, presents them to users, processes responses, and resumes the OAuth flow seamlessly.

## Technical Requirements

### 1. Enhanced Challenge Detection
- **Current**: Basic string matching for "Just a moment..."
- **Enhanced**: Parse full Cloudflare response to extract challenge data
- **Support**: Turnstile CAPTCHA, browser challenges, and rate limiting

### 2. Challenge Presentation System
- **UI Components**: Modal or dedicated page for challenge display
- **JavaScript Integration**: Cloudflare Turnstile widget integration
- **State Management**: Maintain OAuth state through challenge process

### 3. Challenge Response Processing
- **Server Validation**: Verify Turnstile responses server-side
- **OAuth Resumption**: Continue OAuth flow after successful challenge
- **Error Handling**: Graceful failure and retry mechanisms

## Implementation Strategy

### Phase 1: Core Challenge Detection and Storage

#### A. Enhance NationbuilderTokenExchangeService
```ruby
# app/services/nationbuilder_token_exchange_service.rb
class CloudflareChallenge
  attr_reader :type, :site_key, :callback_url, :challenge_data
  
  def self.from_response(response)
    # Parse Cloudflare response to extract challenge details
  end
end

def exchange_code_for_token(code)
  # ... existing code ...
  
  unless res.is_a?(Net::HTTPSuccess)
    if cloudflare_challenge = detect_cloudflare_challenge(res)
      raise TokenExchangeError.new("cloudflare_challenge", challenge: cloudflare_challenge)
    end
    # ... existing error handling ...
  end
end

private

def detect_cloudflare_challenge(response)
  return nil unless response.code == "403"
  
  if response.body.include?("Just a moment...") || 
     response.body.include?("cf-challenge-running") ||
     response.body.include?("turnstile")
    
    CloudflareChallenge.from_response(response)
  end
end
```

#### B. Add Challenge Storage Model
```ruby
# app/models/cloudflare_challenge.rb
class CloudflareChallenge < ApplicationRecord
  belongs_to :user, optional: true
  
  validates :challenge_id, presence: true, uniqueness: true
  validates :oauth_state, presence: true
  validates :challenge_type, inclusion: { in: %w[turnstile browser_challenge rate_limit] }
  
  scope :active, -> { where('expires_at > ?', Time.current) }
  scope :for_session, ->(session_id) { where(session_id: session_id) }
  
  def expired?
    expires_at < Time.current
  end
  
  def challenge_url
    Rails.application.routes.url_helpers.cloudflare_challenge_path(challenge_id)
  end
end
```

### Phase 2: Challenge Presentation Controller

#### A. Create CloudflareChallengeController
```ruby
# app/controllers/cloudflare_challenge_controller.rb
class CloudflareChallengeController < ApplicationController
  allow_unauthenticated_access
  
  before_action :load_challenge, only: [:show, :verify, :complete]
  before_action :check_challenge_validity, only: [:show, :verify, :complete]
  
  def show
    @challenge_data = @challenge.challenge_data
    @site_key = cloudflare_site_key
    @callback_url = verify_cloudflare_challenge_url(@challenge.challenge_id)
  end
  
  def verify
    if verify_turnstile_response(params[:cf_turnstile_response])
      redirect_to complete_cloudflare_challenge_path(@challenge.challenge_id)
    else
      flash.now[:alert] = "Challenge verification failed. Please try again."
      render :show
    end
  end
  
  def complete
    # Resume OAuth flow with original parameters
    redirect_to oauth_callback_with_challenge_completion
  end
  
  private
  
  def verify_turnstile_response(response_token)
    TurnstileVerificationService.new(
      response_token: response_token,
      user_ip: request.remote_ip
    ).verify
  end
  
  def oauth_callback_with_challenge_completion
    # Reconstruct OAuth callback URL with original parameters
    "/auth/nationbuilder/callback?#{@challenge.original_params.to_query}&challenge_completed=true"
  end
end
```

#### B. Add Challenge Routes
```ruby
# config/routes.rb (addition)
resources :cloudflare_challenges, only: [:show], param: :challenge_id do
  member do
    post :verify
    get :complete
  end
end
```

### Phase 3: UI Components and Views

#### A. Challenge Display Component
```ruby
# app/components/cloudflare_challenge_component.rb
class CloudflareChallengeComponent < ViewComponent::Base
  def initialize(challenge:, site_key:, callback_url:)
    @challenge = challenge
    @site_key = site_key
    @callback_url = callback_url
  end
  
  private
  
  attr_reader :challenge, :site_key, :callback_url
  
  def challenge_title
    case challenge.challenge_type
    when 'turnstile'
      'Security Check Required'
    when 'browser_challenge'
      'Browser Verification'
    when 'rate_limit'
      'Rate Limit Protection'
    else
      'Security Verification'
    end
  end
  
  def challenge_description
    case challenge.challenge_type
    when 'turnstile'
      'Please complete the security check below to continue with sign-in.'
    when 'browser_challenge'
      'We need to verify your browser before continuing.'
    when 'rate_limit'
      'Too many requests detected. Please wait and verify to continue.'
    else
      'Please complete the security verification to continue.'
    end
  end
end
```

#### B. Challenge View Template
```erb
<!-- app/components/cloudflare_challenge_component.html.erb -->
<div class="max-w-md mx-auto bg-white rounded-lg shadow-md p-6">
  <div class="text-center mb-6">
    <h2 class="text-2xl font-bold text-gray-900 mb-2"><%= challenge_title %></h2>
    <p class="text-gray-600"><%= challenge_description %></p>
  </div>
  
  <%= form_with url: callback_url, method: :post, local: true, 
                class: "space-y-4", 
                data: { controller: "cloudflare-challenge" } do |form| %>
    
    <div class="flex justify-center">
      <div class="cf-turnstile" 
           data-sitekey="<%= site_key %>"
           data-callback="handleTurnstileSuccess"
           data-error-callback="handleTurnstileError">
      </div>
    </div>
    
    <div class="text-center">
      <%= form.submit "Continue", 
                      class: "w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 disabled:opacity-50",
                      disabled: true,
                      data: { 
                        cloudflare_challenge_target: "submitButton",
                        action: "click->cloudflare-challenge#submit"
                      } %>
    </div>
  <% end %>
  
  <div class="mt-4 text-center">
    <p class="text-sm text-gray-500">
      Having trouble? 
      <%= link_to "Try alternative sign-in", new_session_path, 
                  class: "text-indigo-600 hover:text-indigo-500" %>
    </p>
  </div>
</div>

<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
```

### Phase 4: Enhanced OAuth Flow Integration

#### A. Update NationbuilderAuthController
```ruby
# app/controllers/nationbuilder_auth_controller.rb (modifications)
def callback
  return handle_oauth_error if params[:error]
  return handle_missing_code if params[:code].blank?
  
  # Check if this is a challenge completion callback
  if params[:challenge_completed] == 'true'
    return handle_challenge_completed_callback
  end
  
  # ... existing callback logic ...
rescue NationbuilderTokenExchangeService::TokenExchangeError => e
  if e.message == "cloudflare_challenge" && e.data[:challenge]
    handle_cloudflare_challenge(e.data[:challenge])
  else
    # ... existing error handling ...
  end
end

private

def handle_cloudflare_challenge(challenge_data)
  # Store challenge data and redirect to challenge page
  challenge = CloudflareChallenge.create!(
    challenge_id: SecureRandom.uuid,
    challenge_type: challenge_data.type,
    challenge_data: challenge_data.to_h,
    oauth_state: params[:state],
    original_params: request.query_parameters,
    session_id: session.id,
    expires_at: 15.minutes.from_now,
    user: Current.user
  )
  
  redirect_to cloudflare_challenge_path(challenge.challenge_id)
end

def handle_challenge_completed_callback
  # Resume normal OAuth flow - challenge has been completed
  challenge_id = session[:completed_challenge_id]
  return handle_oauth_error unless challenge_id
  
  challenge = CloudflareChallenge.find_by(challenge_id: challenge_id)
  return handle_oauth_error unless challenge&.active?
  
  # Clear the completed challenge
  session.delete(:completed_challenge_id)
  challenge.destroy
  
  # Continue normal OAuth processing
  if Current.user
    handle_account_linking
  else
    authenticate_with_nationbuilder
  end
end
```

### Phase 5: Turnstile Verification Service

#### A. Server-side Verification
```ruby
# app/services/turnstile_verification_service.rb
class TurnstileVerificationService
  API_ENDPOINT = 'https://challenges.cloudflare.com/turnstile/v0/siteverify'
  
  def initialize(response_token:, user_ip:)
    @response_token = response_token
    @user_ip = user_ip
    @secret_key = Rails.application.credentials.cloudflare_turnstile_secret_key
  end
  
  def verify
    return false if response_token.blank? || secret_key.blank?
    
    response = make_verification_request
    
    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      result['success'] == true
    else
      Rails.logger.error "Turnstile verification failed: #{response.code} #{response.body}"
      false
    end
  rescue => e
    Rails.logger.error "Turnstile verification error: #{e.message}"
    false
  end
  
  private
  
  attr_reader :response_token, :user_ip, :secret_key
  
  def make_verification_request
    uri = URI(API_ENDPOINT)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      secret: secret_key,
      response: response_token,
      remoteip: user_ip
    }.to_json
    
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end
end
```

### Phase 6: Client-side JavaScript Integration

#### A. Stimulus Controller for Challenge Handling
```javascript
// app/javascript/controllers/cloudflare_challenge_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton"]
  
  connect() {
    this.handleTurnstileSuccess = this.handleTurnstileSuccess.bind(this)
    this.handleTurnstileError = this.handleTurnstileError.bind(this)
    
    // Make callbacks available globally for Turnstile
    window.handleTurnstileSuccess = this.handleTurnstileSuccess
    window.handleTurnstileError = this.handleTurnstileError
  }
  
  handleTurnstileSuccess(token) {
    // Enable submit button when challenge is completed
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.textContent = "Continue to Sign In"
    
    // Add token to form
    const tokenInput = document.createElement('input')
    tokenInput.type = 'hidden'
    tokenInput.name = 'cf_turnstile_response'
    tokenInput.value = token
    this.element.appendChild(tokenInput)
  }
  
  handleTurnstileError(error) {
    console.error('Turnstile error:', error)
    this.showError('Challenge failed. Please refresh the page and try again.')
  }
  
  submit(event) {
    if (this.submitButtonTarget.disabled) {
      event.preventDefault()
      this.showError('Please complete the security challenge first.')
    }
  }
  
  showError(message) {
    // Create or update error message display
    let errorDiv = this.element.querySelector('.challenge-error')
    if (!errorDiv) {
      errorDiv = document.createElement('div')
      errorDiv.className = 'challenge-error mt-4 p-3 rounded-md bg-red-50 border border-red-200'
      this.element.appendChild(errorDiv)
    }
    
    errorDiv.innerHTML = `
      <div class="flex">
        <div class="text-sm text-red-700">${message}</div>
      </div>
    `
  }
}
```

## Configuration Requirements

### Environment Variables
```env
# Cloudflare Turnstile Configuration
CLOUDFLARE_TURNSTILE_SITE_KEY=your_site_key_here
CLOUDFLARE_TURNSTILE_SECRET_KEY=your_secret_key_here
```

### Rails Credentials
```yaml
# config/credentials.yml.enc
cloudflare_turnstile_secret_key: your_secret_key_here
```

### Database Migration
```ruby
# db/migrate/xxx_create_cloudflare_challenges.rb
class CreateCloudflareeChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table :cloudflare_challenges do |t|
      t.string :challenge_id, null: false, index: { unique: true }
      t.string :challenge_type, null: false
      t.json :challenge_data
      t.string :oauth_state, null: false
      t.json :original_params
      t.string :session_id, null: false
      t.references :user, null: true, foreign_key: true
      t.datetime :expires_at, null: false
      t.timestamps
    end
    
    add_index :cloudflare_challenges, :session_id
    add_index :cloudflare_challenges, :expires_at
  end
end
```

## Testing Strategy

### Unit Tests
```ruby
# spec/services/turnstile_verification_service_spec.rb
RSpec.describe TurnstileVerificationService do
  describe '#verify' do
    it 'returns true for valid responses' do
      stub_successful_verification
      service = described_class.new(response_token: 'valid_token', user_ip: '127.0.0.1')
      expect(service.verify).to be true
    end
    
    it 'returns false for invalid responses' do
      stub_failed_verification
      service = described_class.new(response_token: 'invalid_token', user_ip: '127.0.0.1')
      expect(service.verify).to be false
    end
  end
end
```

### Integration Tests
```ruby
# spec/requests/cloudflare_challenge_spec.rb
RSpec.describe "Cloudflare Challenge Flow" do
  describe "GET /cloudflare_challenges/:challenge_id" do
    it "displays challenge page for valid challenge" do
      challenge = create(:cloudflare_challenge)
      get cloudflare_challenge_path(challenge.challenge_id)
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('cf-turnstile')
    end
  end
  
  describe "POST /cloudflare_challenges/:challenge_id/verify" do
    it "processes valid turnstile response" do
      challenge = create(:cloudflare_challenge)
      allow_any_instance_of(TurnstileVerificationService).to receive(:verify).and_return(true)
      
      post verify_cloudflare_challenge_path(challenge.challenge_id), 
           params: { cf_turnstile_response: 'valid_token' }
      
      expect(response).to redirect_to(complete_cloudflare_challenge_path(challenge.challenge_id))
    end
  end
end
```

### System Tests
```ruby
# spec/system/nationbuilder_oauth_with_challenge_spec.rb
RSpec.describe "NationBuilder OAuth with Cloudflare Challenge" do
  it "completes OAuth flow after challenge resolution" do
    # Simulate Cloudflare challenge during OAuth
    stub_nationbuilder_challenge_response
    
    visit "/auth/nationbuilder"
    
    # Should be redirected to challenge page
    expect(page).to have_content("Security Check Required")
    expect(page).to have_css(".cf-turnstile")
    
    # Simulate successful challenge completion
    complete_turnstile_challenge
    
    # Should continue to OAuth success
    expect(page).to have_content("Successfully signed in")
  end
end
```

## Deployment Considerations

### Feature Flag Integration
```ruby
# Add to existing feature flag system
def handle_cloudflare_challenge(challenge_data)
  unless feature_enabled?("cloudflare_challenge_handling")
    # Fall back to existing error message
    flash[:alert] = "NationBuilder OAuth is currently blocked by Cloudflare security."
    redirect_to new_session_path
    return
  end
  
  # ... challenge handling logic ...
end
```

### Performance Monitoring
- Add monitoring for challenge completion rates
- Track challenge type distribution
- Monitor verification API response times
- Alert on high challenge failure rates

### Security Considerations
- Rate limit challenge attempts per session
- Expire challenges after reasonable time
- Validate all challenge data on server-side
- Log security events for audit

## Success Metrics

### Primary Metrics
- **OAuth Success Rate**: Target >95% successful completions after challenge
- **Challenge Completion Rate**: Target >90% of presented challenges completed
- **User Experience**: <30 seconds average time to complete challenge flow

### Secondary Metrics
- Challenge type distribution (Turnstile vs browser vs rate limit)
- Time to complete different challenge types
- Fallback usage rate (users who choose alternative sign-in)

## Future Enhancements

### Phase 2 Features
- **Challenge Caching**: Store challenge responses to avoid repeats
- **Progressive Challenges**: Different challenge levels based on risk
- **Alternative Verification**: Phone or email verification options
- **Admin Dashboard**: Challenge analytics and configuration

### Monitoring Integration
- **Real-time Dashboards**: Challenge metrics and success rates
- **Automated Alerts**: High failure rates or API issues
- **User Feedback**: Capture challenge experience feedback

## Implementation Timeline

### Week 1: Core Infrastructure
- Challenge detection and storage
- Basic controller and routing
- Database migration

### Week 2: UI and Integration  
- Challenge display components
- JavaScript integration
- OAuth flow updates

### Week 3: Testing and Polish
- Comprehensive test suite
- Error handling edge cases
- Performance optimization

### Week 4: Deployment and Monitoring
- Production deployment
- Monitoring setup
- Documentation completion

## Risk Mitigation

### Technical Risks
- **Cloudflare API Changes**: Monitor API documentation and version
- **Challenge Types**: Support multiple challenge formats
- **Browser Compatibility**: Test across major browsers

### User Experience Risks
- **Challenge Friction**: Provide clear instructions and alternatives
- **Mobile Experience**: Ensure challenges work on mobile devices
- **Accessibility**: Maintain WCAG compliance

### Security Risks
- **Challenge Bypassing**: Server-side verification required
- **Session Hijacking**: Secure challenge state management
- **Data Exposure**: Encrypt sensitive challenge data

This PRD provides a comprehensive roadmap for implementing Cloudflare challenge handling that will resolve the OAuth deployment blocking issue while maintaining security and user experience standards.