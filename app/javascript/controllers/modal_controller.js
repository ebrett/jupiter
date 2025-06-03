import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Bind escape key to close modal
    this.handleEscape = this.handleEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
  }

  open() {
    this.element.classList.remove("hidden")
    document.addEventListener("keydown", this.handleEscape)
    document.body.style.overflow = "hidden" // Prevent background scrolling
  }

  close() {
    this.element.classList.add("hidden")
    document.removeEventListener("keydown", this.handleEscape)
    document.body.style.overflow = "" // Restore scrolling
  }

  retry() {
    // This method can be overridden by specific modal controllers
    this.close()
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  // Close modal when clicking outside of it
  clickOutside(event) {
    if (event.target === this.element) {
      this.close()
    }
  }
}