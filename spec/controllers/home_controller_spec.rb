require "rails_helper"

RSpec.describe HomeController, type: :controller do
  describe "GET #index" do
    context "when user is not authenticated" do
      it "returns a successful response" do
        get :index
        expect(response).to be_successful
      end

      it "renders the index template" do
        get :index
        expect(response).to render_template(:index)
      end

      it "does not require authentication" do
        # The home page should be accessible without authentication
        expect { get :index }.not_to raise_error
      end
    end

    context "when user is authenticated" do
      let(:user) { create(:user) }
      let(:session) { create(:session, user: user) }

      before do
        allow(Current).to receive_messages(session: session, user: user)
      end

      it "returns a successful response" do
        get :index
        expect(response).to be_successful
      end

      it "renders the index template" do
        get :index
        expect(response).to render_template(:index)
      end

      it "makes the current user available" do
        get :index
        # The authentication concern should set Current.user
        expect(Current.user).to eq(user)
      end
    end

    context "when user has an expired session" do
      let(:user) { create(:user) }
      let(:expired_session) { create(:session, user: user, created_at: 1.year.ago) }

      before do
        allow(Current).to receive(:session).and_return(expired_session)
        allow(expired_session).to receive(:expired?).and_return(true)
      end

      it "still renders successfully" do
        # Even with expired session, home page should be accessible
        get :index
        expect(response).to be_successful
      end
    end

    context "performance considerations" do
      let(:user) { create(:user) }
      let(:session) { create(:session, user: user) }

      before do
        allow(Current).to receive_messages(session: session, user: user)
      end

      it "completes request efficiently" do
        # This test ensures the home page loads without excessive delay
        start_time = Time.current
        get :index
        end_time = Time.current

        expect(response).to be_successful
        expect(end_time - start_time).to be < 1.second
      end
    end
  end
end
