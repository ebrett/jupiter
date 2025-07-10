require 'rails_helper'

RSpec.describe CloudflareChallengeComponent, type: :component do
  let(:challenge_data) { { 'turnstile_present' => true } }
  let(:site_key) { 'test-site-key-123' }
  let(:callback_url) { '/cloudflare_challenges/test-id/verify' }

  let(:component) do
    described_class.new(
      challenge_data: challenge_data,
      site_key: site_key,
      callback_url: callback_url
    )
  end

  describe 'initialization' do
    it 'accepts required parameters' do
      expect(component.challenge_data).to eq(challenge_data)
      expect(component.site_key).to eq(site_key)
      expect(component.callback_url).to eq(callback_url)
    end

    it 'sets default challenge type from challenge_data' do
      expect(component.challenge_type).to eq('turnstile')
    end

    context 'with browser challenge data' do
      let(:challenge_data) { { 'challenge_stage_present' => true } }

      it 'detects browser challenge type' do
        expect(component.challenge_type).to eq('browser_challenge')
      end
    end

    context 'with rate limit data' do
      let(:challenge_data) { { 'rate_limited' => true } }

      it 'detects rate limit type' do
        expect(component.challenge_type).to eq('rate_limit')
      end
    end
  end

  describe 'rendering' do
    subject { render_inline(component).to_html }

    it 'renders the security check title' do
      expect(subject).to include('Security Check Required')
    end

    it 'renders the instruction text' do
      expect(subject).to include('Please complete the security check below')
    end

    it 'includes form with correct action URL' do
      expect(subject).to include("action=\"#{callback_url}\"")
      expect(subject).to include('method="post"')
    end

    it 'includes submit button' do
      expect(subject).to include('type="submit"')
      expect(subject).to include('Continue')
    end

    it 'includes alternative sign-in link' do
      expect(subject).to include('Try alternative sign-in')
      expect(subject).to include('href="/sign-in"')
    end

    context 'with turnstile challenge' do
      it 'includes Turnstile widget div' do
        expect(subject).to include('class="cf-turnstile"')
        expect(subject).to include("data-sitekey=\"#{site_key}\"")
      end

      it 'includes Turnstile script' do
        expect(subject).to include('https://challenges.cloudflare.com/turnstile/v0/api.js')
      end

      it 'includes JavaScript callbacks' do
        expect(subject).to include('handleTurnstileSuccess')
        expect(subject).to include('handleTurnstileError')
      end

      it 'disables submit button by default' do
        expect(subject).to include('disabled')
        expect(subject).to include('id="challenge-submit-button"')
      end
    end

    context 'with browser challenge' do
      subject { render_inline(component).to_html }

      let(:challenge_data) { { 'challenge_stage_present' => true } }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("NATIONBUILDER_NATION_SLUG").and_return("test-nation")
        allow(ENV).to receive(:[]).with("NATIONBUILDER_CLIENT_ID").and_return("test-client-id")
        allow(ENV).to receive(:[]).with("NATIONBUILDER_REDIRECT_URI").and_return("http://localhost:3000/callback")
      end

      it 'shows browser challenge title' do
        expect(subject).to include('Browser Verification Required')
      end

      it 'shows manual verification instructions' do
        expect(subject).to include('You\'re being asked to verify your browser for security reasons')
      end

      it 'includes step-by-step instructions' do
        expect(subject).to include('step-number')
        expect(subject).to include('>1<')
        expect(subject).to include('>2<')
        expect(subject).to include('>3<')
        expect(subject).to include('>4<')
      end

      it 'includes "Open Verification Page" button' do
        expect(subject).to include('Open Verification Page')
        expect(subject).to include('target="_blank"')
      end

      it 'includes "Continue Sign-in" button' do
        expect(subject).to include('Continue Sign-in')
        expect(subject).to include('type="submit"')
      end

      it 'enables the continue button for manual verification' do
        expect(subject).not_to include('disabled="disabled"')
        expect(subject).not_to include('disabled=true')
      end

      it 'does not include Turnstile widget' do
        expect(subject).not_to include('cf-turnstile')
      end

      it 'includes visual indicators for numbered steps' do
        expect(subject).to include('step-number')
        expect(subject).to include('step-content')
      end

      it 'includes mobile-responsive instruction layout' do
        expect(subject).to include('space-y-4')
        expect(subject).to include('text-sm')
        expect(subject).to include('sm:text-base')
      end

      it 'includes help text for manual verification' do
        expect(subject).to include('Complete any security checks')
        expect(subject).to include('return here and click')
      end

      it 'shows NationBuilder-specific instructions' do
        expect(subject).to include('NationBuilder page')
      end
    end

    context 'with rate limit challenge' do
      subject { render_inline(component).to_html }

      let(:challenge_data) { { 'rate_limited' => true } }


      it 'shows rate limit message' do
        expect(subject).to include('Too many requests')
      end

      it 'shows wait instruction' do
        expect(subject).to include('wait')
      end

      it 'disables form submission' do
        expect(subject).to include('disabled')
      end
    end
  end

  describe 'helper methods' do
    describe '#challenge_title' do
      it 'returns security check title for turnstile' do
        expect(component.send(:challenge_title)).to eq('Security Check Required')
      end

      context 'with browser challenge' do
        let(:challenge_data) { { 'challenge_stage_present' => true } }

        it 'returns browser verification title' do
          expect(component.send(:challenge_title)).to eq('Browser Verification Required')
        end
      end

      context 'with rate limit' do
        let(:challenge_data) { { 'rate_limited' => true } }

        it 'returns rate limit title' do
          expect(component.send(:challenge_title)).to eq('Too Many Requests')
        end
      end
    end

    describe '#challenge_description' do
      it 'returns appropriate description for turnstile' do
        description = component.send(:challenge_description)
        expect(description).to include('security check')
        expect(description).to include('continue')
      end

      context 'with browser challenge' do
        let(:challenge_data) { { 'challenge_stage_present' => true } }

        it 'returns manual verification description' do
          description = component.send(:challenge_description)
          expect(description).to include('follow the steps below')
          expect(description).to include('manual verification')
        end
      end

      context 'with rate limit' do
        let(:challenge_data) { { 'rate_limited' => true } }

        it 'returns rate limit description' do
          description = component.send(:challenge_description)
          expect(description).to include('many requests')
          expect(description).to include('wait')
        end
      end
    end

    describe '#submit_button_disabled?' do
      it 'returns true for turnstile challenges' do
        expect(component.send(:submit_button_disabled?)).to be true
      end

      context 'with browser challenge' do
        let(:challenge_data) { { 'challenge_stage_present' => true } }

        it 'returns false for browser challenges' do
          expect(component.send(:submit_button_disabled?)).to be false
        end
      end

      context 'with rate limit' do
        let(:challenge_data) { { 'rate_limited' => true } }

        it 'returns true for rate limit challenges' do
          expect(component.send(:submit_button_disabled?)).to be true
        end
      end
    end

    describe '#show_manual_verification?' do
      it 'returns false for turnstile challenges' do
        expect(component.send(:show_manual_verification?)).to be false
      end

      context 'with browser challenge' do
        let(:challenge_data) { { 'challenge_stage_present' => true } }

        it 'returns true for browser challenges' do
          expect(component.send(:show_manual_verification?)).to be true
        end
      end

      context 'with rate limit' do
        let(:challenge_data) { { 'rate_limited' => true } }

        it 'returns false for rate limit challenges' do
          expect(component.send(:show_manual_verification?)).to be false
        end
      end
    end

    describe '#verification_url' do
      context 'with browser challenge' do
        let(:challenge_data) { { 'challenge_stage_present' => true } }

        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with("NATIONBUILDER_NATION_SLUG").and_return("test-nation")
          allow(ENV).to receive(:[]).with("NATIONBUILDER_CLIENT_ID").and_return("test-client-id")
          allow(ENV).to receive(:[]).with("NATIONBUILDER_REDIRECT_URI").and_return("http://localhost:3000/callback")
        end

        it 'returns the OAuth URL for manual verification' do
          expect(component.send(:verification_url)).to include('nationbuilder.com/oauth/authorize')
        end

        context 'with missing ENV variables' do
          before do
            allow(ENV).to receive(:[]).with("NATIONBUILDER_NATION_SLUG").and_return(nil)
          end

          it 'returns nil when ENV variables are missing' do
            expect(component.send(:verification_url)).to be_nil
          end
        end
      end
    end
  end

  describe 'accessibility' do
    subject { render_inline(component).to_html }

    it 'includes semantic HTML structure' do
      expect(subject).to include('<main')
      expect(subject).to include('<form')
      expect(subject).to include('<input')
    end

    it 'includes proper heading hierarchy' do
      expect(subject).to include('<h1')
    end

    it 'includes form accessibility features' do
      expect(subject).to include('id="challenge-submit-button"')
      expect(subject).to include('type="submit"')
    end
  end

  describe 'responsive design' do
    subject { render_inline(component).to_html }

    it 'includes responsive container classes' do
      expect(subject).to include('min-h-screen')
      expect(subject).to include('flex')
      expect(subject).to include('items-center')
      expect(subject).to include('justify-center')
    end

    it 'includes mobile-responsive padding' do
      expect(subject).to include('px-4')
      expect(subject).to include('sm:px-6')
      expect(subject).to include('lg:px-8')
    end

    it 'includes responsive layout classes' do
      expect(subject).to include('max-w-md')
      expect(subject).to include('w-full')
    end
  end

  describe 'error handling' do
    context 'with missing site_key for turnstile' do
      let(:site_key) { nil }

      it 'still renders without breaking' do
        expect { render_inline(component) }.not_to raise_error
      end

      it 'shows fallback message' do
        rendered = render_inline(component).to_html
        expect(rendered).to include('configuration issue')
      end
    end

    context 'with invalid challenge_data' do
      let(:challenge_data) { {} }

      it 'defaults to unknown challenge type' do
        expect(component.challenge_type).to eq('unknown')
      end

      it 'shows generic challenge message' do
        rendered = render_inline(component).to_html
        expect(rendered).to include('verification required')
      end
    end
  end
end
