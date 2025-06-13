require "rails_helper"

RSpec.describe ModalComponent, type: :component do
  it "renders modal with default settings" do
    render_inline(described_class.new(id: "test-modal")) { "Modal content" }

    expect(rendered_content).to include('id="test-modal"')
    expect(rendered_content).to include("fixed inset-0 z-50")
    expect(rendered_content).to include("Modal content")
    expect(rendered_content).to include('data-controller="modal"')
  end

  it "renders modal with title" do
    render_inline(described_class.new(id: "test-modal", title: "Test Title")) { "Content" }

    expect(rendered_content).to include("<h3")
    expect(rendered_content).to include("Test Title")
    expect(rendered_content).to include('aria-label="Close modal"')
  end

  it "renders modal without close button when not closeable" do
    render_inline(described_class.new(id: "test-modal", title: "Test", closeable: false)) { "Content" }

    expect(rendered_content).to include("Test")
    expect(rendered_content).not_to include('aria-label="Close modal"')
    expect(rendered_content).to include('data-modal-closeable-value="false"')
  end

  it "applies correct size classes" do
    render_inline(described_class.new(id: "small-modal", size: :sm)) { "Content" }
    expect(rendered_content).to include("max-w-md")

    render_inline(described_class.new(id: "large-modal", size: :lg)) { "Content" }
    expect(rendered_content).to include("max-w-2xl")

    render_inline(described_class.new(id: "default-modal")) { "Content" }
    expect(rendered_content).to include("max-w-lg")
  end
end
