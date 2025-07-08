require 'rails_helper'

RSpec.describe CloudflareConfig do
  describe '.turnstile_site_key' do
    it 'returns site key from environment' do
      allow(ENV).to receive(:[]).with('CLOUDFLARE_TURNSTILE_SITE_KEY').and_return('test-site-key')
      expect(described_class.turnstile_site_key).to eq('test-site-key')
    end
  end

  describe '.turnstile_secret_key' do
    context 'when environment variable is set' do
      it 'returns secret key from environment' do
        allow(ENV).to receive(:[]).with('CLOUDFLARE_TURNSTILE_SECRET_KEY').and_return('test-secret')
        allow(ENV).to receive(:[]).with('CLOUDFLARE_TURNSTILE_SITE_KEY').and_call_original
        expect(described_class.turnstile_secret_key).to eq('test-secret')
      end
    end

    context 'when environment variable is not set' do
      it 'returns secret key from Rails credentials' do
        allow(ENV).to receive(:[]).with('CLOUDFLARE_TURNSTILE_SECRET_KEY').and_return(nil)
        allow(Rails.application.credentials).to receive(:cloudflare_turnstile_secret_key).and_return('credentials-secret')
        expect(described_class.turnstile_secret_key).to eq('credentials-secret')
      end
    end
  end

  describe '.configured?' do
    context 'when both keys are present' do
      it 'returns true' do
        allow(described_class).to receive_messages(turnstile_site_key: 'site-key', turnstile_secret_key: 'secret-key')
        expect(described_class.configured?).to be true
      end
    end

    context 'when site key is missing' do
      it 'returns false' do
        allow(described_class).to receive_messages(turnstile_site_key: nil, turnstile_secret_key: 'secret-key')
        expect(described_class.configured?).to be false
      end
    end

    context 'when secret key is missing' do
      it 'returns false' do
        allow(described_class).to receive_messages(turnstile_site_key: 'site-key', turnstile_secret_key: nil)
        expect(described_class.configured?).to be false
      end
    end
  end

  describe '.verification_endpoint' do
    it 'returns Cloudflare Turnstile API endpoint' do
      expect(described_class.verification_endpoint).to eq('https://challenges.cloudflare.com/turnstile/v0/siteverify')
    end
  end
end
