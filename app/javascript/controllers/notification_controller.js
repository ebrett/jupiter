import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification"
export default class extends Controller {
  static targets = ["container"]

  dismiss() {
    this.element.remove()
  }

  connect() {
    // Auto-dismiss after 5 seconds if configured
    if (this.data.has("autoDismiss")) {
      const delay = parseInt(this.data.get("autoDismiss")) || 5000
      setTimeout(() => {
        this.dismiss()
      }, delay)
    }
  }
}