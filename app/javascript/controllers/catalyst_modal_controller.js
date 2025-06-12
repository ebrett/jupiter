import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["panel", "title", "description"]
  static values = { open: Boolean }

  connect() {
    this.handleEscape = this.handleEscape.bind(this)
    this.updateVisibility()
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
    this.restoreBodyScroll()
  }

  openValueChanged() {
    this.updateVisibility()
  }

  open() {
    this.openValue = true
  }

  close() {
    this.openValue = false
  }

  clickBackdrop(event) {
    // Only close if clicking the backdrop itself, not the panel
    if (event.target === this.element) {
      this.close()
    }
  }

  clickPanel(event) {
    // Prevent clicks on the panel from bubbling up to the backdrop
    event.stopPropagation()
  }

  updateVisibility() {
    if (this.openValue) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.element.style.display = "flex"
    document.addEventListener("keydown", this.handleEscape)
    document.body.style.overflow = "hidden"
    
    // Add transition classes
    requestAnimationFrame(() => {
      this.element.classList.remove("data-closed")
      this.element.classList.add("data-enter")
    })
  }

  hide() {
    this.element.classList.add("data-closed")
    this.element.classList.remove("data-enter")
    
    // Wait for transition to complete before hiding
    setTimeout(() => {
      if (!this.openValue) {
        this.element.style.display = "none"
      }
    }, 100)
    
    document.removeEventListener("keydown", this.handleEscape)
    this.restoreBodyScroll()
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  restoreBodyScroll() {
    document.body.style.overflow = ""
  }
}