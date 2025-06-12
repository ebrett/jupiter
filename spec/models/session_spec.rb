require "rails_helper"

RSpec.describe Session, type: :model do
  let(:user) { create(:user) }

  describe "associations" do
    it "belongs to user" do
      session = create(:session, user: user)
      expect(session.user).to eq(user)
    end
  end

  describe "remember me functionality" do
    context "when remember_me is false" do
      let(:session) { create(:session, user: user, remember_me: false) }

      it "uses default session duration" do
        expect(session.expires_at).to be_within(1.minute).of(session.created_at + Session::DEFAULT_SESSION_DURATION)
      end

      it "is not expired within default duration" do
        travel_to 1.week.from_now do
          expect(session.expired?).to be false
        end
      end

      it "is expired after default duration" do
        session # Create the session first
        travel_to 3.weeks.from_now do
          expect(session.reload.expired?).to be true
        end
      end
    end

    context "when remember_me is true" do
      let(:session) { create(:session, user: user, remember_me: true) }

      it "uses extended session duration" do
        expect(session.expires_at).to be_within(1.minute).of(session.created_at + Session::REMEMBER_ME_DURATION)
      end

      it "is not expired within extended duration" do
        travel_to 3.months.from_now do
          expect(session.expired?).to be false
        end
      end

      it "is expired after extended duration" do
        session # Create the session first
        travel_to 7.months.from_now do
          expect(session.reload.expired?).to be true
        end
      end
    end
  end

  describe "#time_until_expiry" do
    let(:session) { create(:session, user: user, remember_me: false) }

    it "returns time until expiry for active session" do
      session # Create the session first
      travel_to 1.day.from_now do
        expected_time = (Session::DEFAULT_SESSION_DURATION - 1.day).to_f
        expect(session.reload.time_until_expiry).to be_within(1.minute).of(expected_time)
      end
    end

    it "returns nil for expired session" do
      session # Create the session first
      travel_to 3.weeks.from_now do
        expect(session.reload.time_until_expiry).to be_nil
      end
    end
  end

  describe "default values" do
    let(:session) { create(:session, user: user) }

    it "defaults remember_me to false" do
      expect(session.remember_me).to be false
    end
  end
end
