# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::DividerComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:doc) { render_component(component) }

  describe "basic rendering" do
    it "renders an hr element with correct attributes" do
      expect(doc).to have_css("hr[role='presentation']")
      expect(doc).to have_css("hr.w-full.border-t")
    end

    it "applies default border opacity" do
      hr = doc.find("hr")
      expect(hr[:class]).to include("border-zinc-950/10")
    end
  end

  describe "soft variant" do
    let(:options) { { soft: true } }

    it "applies soft border opacity" do
      hr = doc.find("hr")
      expect(hr[:class]).to include("border-zinc-950/5")
      expect(hr[:class]).not_to include("border-zinc-950/10")
    end
  end

  describe "customization" do
    context "with custom classes" do
      let(:options) { { class: "custom-divider" } }

      it "applies custom classes" do
        expect(doc).to have_css("hr.custom-divider")
      end
    end

    context "with additional HTML options" do
      let(:options) { { id: "custom-divider", "data-test" => "divider" } }

      it "merges additional HTML options" do
        expect(doc).to have_css("hr#custom-divider")
        expect(doc).to have_css("hr[data-test='divider']")
      end
    end
  end
end
