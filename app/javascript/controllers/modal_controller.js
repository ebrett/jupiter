import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]
  static values = { closeable: Boolean }

  connect() {
    this.handleEscape = this.handleEscape.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape)
    document.body.style.overflow = ""
  }

  open() {
    this.element.style.display = "flex"
    document.addEventListener("keydown", this.handleEscape)
    document.addEventListener("click", this.handleClickOutside)
    document.body.style.overflow = "hidden"
  }

  close() {
    if (!this.closeableValue) return
    
    this.element.style.display = "none"
    document.removeEventListener("keydown", this.handleEscape)
    document.removeEventListener("click", this.handleClickOutside)
    document.body.style.overflow = ""
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.closeableValue) {
      this.close()
    }
  }

  handleClickOutside(event) {
    if (this.closeableValue && !this.dialogTarget.contains(event.target)) {
      this.close()
    }
  }
}