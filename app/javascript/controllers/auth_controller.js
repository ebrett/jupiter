import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  static values = { mode: String }

  connect() {
    this.updateFormAction()
  }

  switchToLogin() {
    this.modeValue = "login"
    this.updateModal()
  }

  switchToRegister() {
    this.modeValue = "register"
    this.updateModal()
  }

  updateModal() {
    // Close current modal
    const modal = document.getElementById("auth-modal")
    const modalController = this.application.getControllerForElementAndIdentifier(modal, "modal")
    modalController.close()

    // Update modal content based on mode
    this.updateFormAction()
    
    // Reopen modal with new content
    setTimeout(() => {
      modalController.open()
    }, 100)
  }

  updateFormAction() {
    if (this.hasFormTarget) {
      const isLogin = this.modeValue === "login"
      const action = isLogin ? "/session" : "/users"
      const method = isLogin ? "post" : "post"
      
      this.formTarget.action = action
      this.formTarget.method = method
    }
  }

  openLogin() {
    this.modeValue = "login"
    this.openModal()
  }

  openRegister() {
    this.modeValue = "register"
    this.openModal()
  }

  openModal() {
    const modal = document.getElementById("auth-modal")
    if (modal) {
      this.updateFormAction()
      // Directly show the modal and prevent body scrolling
      modal.style.display = "flex"
      document.body.style.overflow = "hidden"
      
      // Add event listeners for closing
      const closeButton = modal.querySelector('[data-action*="modal#close"]')
      if (closeButton) {
        closeButton.addEventListener('click', () => this.closeModal())
      }
      
      // Close on escape
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') this.closeModal()
      })
      
      // Close on backdrop click
      modal.addEventListener('click', (e) => {
        if (e.target === modal) this.closeModal()
      })
    } else {
      console.error("Auth modal not found")
    }
  }

  closeModal() {
    const modal = document.getElementById("auth-modal")
    if (modal) {
      modal.style.display = "none"
      document.body.style.overflow = ""
    }
  }
}