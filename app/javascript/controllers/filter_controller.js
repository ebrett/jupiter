import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "email", "status"]
  static values = {
    debounceMs: { type: Number, default: 300 }
  }

  connect() {
    this.debouncedSubmit = this.debounce(this.submit.bind(this), this.debounceMsValue)
  }

  filter() {
    this.debouncedSubmit()
  }

  submit() {
    this.formTarget.requestSubmit()
  }

  // Debounce helper to prevent too many requests
  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }
} 