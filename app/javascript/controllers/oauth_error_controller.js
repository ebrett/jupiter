import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "title", "message", "retryBtn"]
  static values = { 
    retryUrl: String,
    errorType: String,
    canRetry: Boolean 
  }

  connect() {
    // Auto-show modal if there's an OAuth error in flash
    const flashAlert = document.querySelector('[data-oauth-error]')
    if (flashAlert && flashAlert.dataset.oauthErrorData) {
      try {
        const errorData = JSON.parse(flashAlert.dataset.oauthErrorData)
        this.showError(
          errorData.title,
          errorData.message,
          errorData.error_type,
          errorData.can_retry
        )
      } catch (e) {
        // Fallback to simple error display
        this.showError(
          "Authentication Error",
          flashAlert.dataset.oauthError || "An error occurred",
          "general",
          true
        )
      }
    }
  }

  showError(title, message, errorType = "general", canRetry = true) {
    this.errorTypeValue = errorType
    this.canRetryValue = canRetry
    
    // Update modal content
    document.getElementById("oauth-error-title").textContent = title
    document.getElementById("oauth-error-message").textContent = message
    
    // Configure retry button based on error type
    const retryBtn = document.getElementById("oauth-retry-btn")
    if (canRetry) {
      retryBtn.style.display = "block"
      this.configureRetryButton(errorType)
    } else {
      retryBtn.style.display = "none"
    }
    
    // Show modal
    document.getElementById("oauth-error-modal").classList.remove("hidden")
    
    // Add escape key listener
    document.addEventListener("keydown", this.handleEscape.bind(this))
  }

  configureRetryButton(errorType) {
    const retryBtn = document.getElementById("oauth-retry-btn")
    
    switch (errorType) {
      case "authentication_error":
        retryBtn.textContent = "Sign In Again"
        this.retryUrlValue = "/auth/nationbuilder"
        break
      case "network_error":
        retryBtn.textContent = "Retry Connection"
        this.retryUrlValue = window.location.href
        break
      case "token_expired":
        retryBtn.textContent = "Reconnect Account"
        this.retryUrlValue = "/auth/nationbuilder"
        break
      case "permissions_error":
        retryBtn.textContent = "Review Permissions"
        this.retryUrlValue = "/auth/nationbuilder"
        break
      default:
        retryBtn.textContent = "Try Again"
        this.retryUrlValue = "/auth/nationbuilder"
    }
  }

  retry() {
    if (this.retryUrlValue) {
      window.location.href = this.retryUrlValue
    } else {
      // Fallback to page refresh
      window.location.reload()
    }
  }

  close() {
    document.getElementById("oauth-error-modal").classList.add("hidden")
    document.removeEventListener("keydown", this.handleEscape.bind(this))
    
    // Remove any flash message elements
    const flashAlert = document.querySelector('[data-oauth-error]')
    if (flashAlert) {
      flashAlert.remove()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  // Static method to show error from anywhere in the app
  static showError(title, message, errorType = "general", canRetry = true) {
    const controller = document.querySelector('[data-controller*="oauth-error"]')
    if (controller && controller.oauthErrorController) {
      controller.oauthErrorController.showError(title, message, errorType, canRetry)
    } else {
      // Fallback: create a temporary controller instance
      const tempDiv = document.createElement('div')
      tempDiv.setAttribute('data-controller', 'oauth-error')
      document.body.appendChild(tempDiv)
      
      // Initialize Stimulus controller
      window.Stimulus.register("oauth-error", OauthErrorController)
      
      setTimeout(() => {
        const newController = tempDiv.oauthErrorController
        if (newController) {
          newController.showError(title, message, errorType, canRetry)
        }
      }, 100)
    }
  }
}