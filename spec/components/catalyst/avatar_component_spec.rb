# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::AvatarComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:doc) { render_component(component) }

  describe "basic rendering" do
    context "with no content" do
      it "renders empty avatar span" do
        expect(doc).to have_css("span[data-slot='avatar']")
      end

      it "includes test selector" do
        expect(doc).to have_css("span[data-test='avatar']")
      end

      it "applies default styling" do
        avatar = doc.find("span[data-slot='avatar']")
        expect(avatar[:class]).to include("inline-grid", "size-8", "rounded-full")
      end
    end

    context "with initials" do
      let(:options) { { initials: "JD" } }

      it "renders initials in SVG" do
        expect(doc).to have_css("svg text", text: "JD")
      end

      it "applies SVG styling" do
        svg = doc.find("svg")
        expect(svg[:class]).to include("size-full", "fill-current", "font-medium", "uppercase")
      end

      it "has proper SVG attributes" do
        svg = doc.find("svg")
        expect(svg[:viewbox]).to eq("0 0 100 100")
        expect(svg[:"aria-hidden"]).to eq("true")
      end

      it "centers text in SVG" do
        text = doc.find("svg text")
        expect(text[:x]).to eq("50%")
        expect(text[:y]).to eq("50%")
        expect(text[:"text-anchor"]).to eq("middle")
      end
    end

    context "with image" do
      let(:options) { { src: "/path/to/image.jpg", alt: "John Doe" } }

      it "renders image" do
        expect(doc).to have_css("img")
      end

      it "sets image attributes" do
        img = doc.find("img")
        expect(img[:src]).to eq("/path/to/image.jpg")
        expect(img[:alt]).to eq("John Doe")
        expect(img[:loading]).to eq("lazy")
      end

      it "applies image styling" do
        img = doc.find("img")
        expect(img[:class]).to include("size-full", "object-cover")
      end

      it "includes error handling" do
        img = doc.find("img")
        expect(img[:onerror]).to eq("this.style.display='none'")
      end
    end

    context "with both initials and image" do
      let(:options) { { src: "/image.jpg", initials: "JD", alt: "John Doe" } }

      it "renders both initials and image" do
        expect(doc).to have_css("svg text", text: "JD")
        expect(doc).to have_css("img")
      end

      it "layers image over initials" do
        # Both should be present for fallback
        expect(doc).to have_css("svg")
        expect(doc).to have_css("img")
      end
    end
  end

  describe "sizes" do
    Catalyst::AvatarComponent::SIZES.each do |size_name, size_class|
      context "#{size_name} size" do
        let(:options) { { size: size_name, initials: "JD" } }

        it "applies correct size class" do
          avatar = doc.find("span[data-slot='avatar']")
          expect(avatar[:class]).to include(size_class)
        end

        it "applies appropriate font size" do
          svg = doc.find("svg")
          expected_font_class = case size_name
          when :xs, :sm
                                 "text-xs"
          when :md
                                 "text-sm"
          when :lg, :xl
                                 "text-base"
          when :"2xl"
                                 "text-lg"
          else
                                 "text-sm"
          end
          expect(svg[:class]).to include(expected_font_class)
        end
      end
    end

    context "invalid size" do
      let(:options) { { size: :invalid } }

      it "raises an error" do
        expect { component }.to raise_error(ArgumentError, "Invalid size: invalid")
      end
    end
  end

  describe "shapes" do
    context "round avatar (default)" do
      let(:options) { { initials: "JD" } }

      it "applies round styling" do
        avatar = doc.find("span[data-slot='avatar']")
        expect(avatar[:class]).to include("rounded-full", "*:rounded-full")
      end
    end

    context "square avatar" do
      let(:options) { { initials: "JD", square: true } }

      it "applies square styling" do
        avatar = doc.find("span[data-slot='avatar']")
        expect(avatar[:class]).to include("rounded-[--avatar-radius]", "*:rounded-[--avatar-radius]")
      end
    end
  end

  describe "clickable avatars" do
    context "with clickable: true" do
      let(:options) { { initials: "JD", clickable: true } }

      it "renders as button" do
        expect(doc).to have_css("button")
        expect(doc).not_to have_css("span[data-slot='avatar']")
      end

      it "includes avatar content in button" do
        expect(doc).to have_css("button svg text", text: "JD")
      end

      it "applies button styling" do
        button = doc.find("button")
        expect(button[:class]).to include("relative", "inline-grid", "focus:outline-none")
      end

      it "includes test selector for button" do
        expect(doc).to have_css("button[data-test='avatar-button']")
      end
    end

    context "with href" do
      let(:options) { { initials: "JD", href: "/profile" } }

      it "renders as link" do
        expect(doc).to have_css("a[href='/profile']")
      end

      it "includes avatar content in link" do
        expect(doc).to have_css("a svg text", text: "JD")
      end

      it "applies link styling" do
        link = doc.find("a")
        expect(link[:class]).to include("relative", "inline-grid")
      end

      it "automatically becomes clickable" do
        link = doc.find("a")
        expect(link[:class]).to include("hover:opacity-75")
      end
    end

    context "square clickable avatar" do
      let(:options) { { initials: "JD", clickable: true, square: true } }

      it "applies square styling to button" do
        button = doc.find("button")
        expect(button[:class]).to include("rounded-[20%]")
      end
    end
  end

  describe "initials processing" do
    context "with single name" do
      let(:options) { { initials: "john" } }

      it "uppercase and limits to 2 characters" do
        expect(doc).to have_css("svg text", text: "JO")
      end
    end

    context "with long initials" do
      let(:options) { { initials: "johnsmith" } }

      it "limits to first 2 characters" do
        expect(doc).to have_css("svg text", text: "JO")
      end
    end

    context "with whitespace" do
      let(:options) { { initials: "  jd  " } }

      it "trims whitespace" do
        expect(doc).to have_css("svg text", text: "JD")
      end
    end

    context "with empty initials" do
      let(:options) { { initials: "" } }

      it "does not render SVG" do
        expect(doc).not_to have_css("svg")
      end
    end
  end

  describe "accessibility" do
    context "with alt text" do
      let(:options) { { initials: "JD", alt: "John Doe" } }

      it "includes title in SVG" do
        expect(doc).to have_css("svg title", text: "John Doe")
      end

      it "does not hide SVG from screen readers" do
        svg = doc.find("svg")
        expect(svg[:"aria-hidden"]).to be_nil
      end
    end

    context "without alt text" do
      let(:options) { { initials: "JD" } }

      it "hides SVG from screen readers" do
        svg = doc.find("svg")
        expect(svg[:"aria-hidden"]).to eq("true")
      end

      it "does not include title" do
        expect(doc).not_to have_css("svg title")
      end
    end

    context "with image and alt text" do
      let(:options) { { src: "/image.jpg", alt: "Profile picture" } }

      it "sets alt attribute on image" do
        img = doc.find("img")
        expect(img[:alt]).to eq("Profile picture")
      end
    end
  end

  describe "custom attributes" do
    let(:options) do
      {
        initials: "JD",
        id: "custom-avatar",
        class: "custom-class",
        data: { user: "123" }
      }
    end

    it "passes through custom attributes" do
      avatar = doc.find("span[data-slot='avatar']")
      expect(avatar[:id]).to eq("custom-avatar")
      expect(avatar[:"data-user"]).to eq("123")
    end

    it "merges custom classes" do
      avatar = doc.find("span[data-slot='avatar']")
      expect(avatar[:class]).to include("custom-class")
    end
  end

  describe "grid layout" do
    let(:options) { { src: "/image.jpg", initials: "JD", alt: "John Doe" } }

    it "uses CSS grid for layering" do
      avatar = doc.find("span[data-slot='avatar']")
      expect(avatar[:class]).to include("inline-grid", "*:col-start-1", "*:row-start-1")
    end

    it "positions all children in same grid cell" do
      # This ensures image overlays initials properly
      avatar = doc.find("span[data-slot='avatar']")
      expect(avatar[:class]).to include("*:col-start-1", "*:row-start-1")
    end
  end

  describe "visual styling" do
    let(:options) { { initials: "JD" } }

    it "includes outline for definition" do
      avatar = doc.find("span[data-slot='avatar']")
      expect(avatar[:class]).to include("outline", "-outline-offset-1", "outline-black/10")
    end

    it "includes dark mode outline" do
      avatar = doc.find("span[data-slot='avatar']")
      expect(avatar[:class]).to include("dark:outline-white/10")
    end

    it "prevents text selection on initials" do
      svg = doc.find("svg")
      expect(svg[:class]).to include("select-none")
    end
  end

  describe "helper methods" do
    describe ".initials_from_name" do
      it "generates initials from single name" do
        expect(described_class.initials_from_name("John")).to eq("JO")
      end

      it "generates initials from first and last name" do
        expect(described_class.initials_from_name("John Doe")).to eq("JD")
      end

      it "generates initials from multiple names" do
        expect(described_class.initials_from_name("John Michael Doe")).to eq("JD")
      end

      it "handles empty string" do
        expect(described_class.initials_from_name("")).to eq("")
      end

      it "handles nil" do
        expect(described_class.initials_from_name(nil)).to eq("")
      end

      it "handles whitespace" do
        expect(described_class.initials_from_name("  John   Doe  ")).to eq("JD")
      end

      it "handles single character names" do
        expect(described_class.initials_from_name("A B")).to eq("AB")
      end
    end
  end

  describe "edge cases" do
    context "with nil values" do
      let(:options) { { src: nil, initials: nil, alt: nil } }

      it "renders empty avatar without errors" do
        expect(doc).to have_css("span[data-slot='avatar']")
        expect(doc).not_to have_css("svg")
        expect(doc).not_to have_css("img")
      end
    end

    context "with empty strings" do
      let(:options) { { src: "", initials: "", alt: "" } }

      it "treats empty strings as no content" do
        expect(doc).to have_css("span[data-slot='avatar']")
        expect(doc).not_to have_css("svg")
        expect(doc).not_to have_css("img")
      end
    end
  end
end
