import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  static values = { mode: String }

  connect() {
    this.updateFormAction()
  }

  openLogin() {
    this.modeValue = "login"
    this.openModal().then(() => {
      this.updateFormAction()
      this.updateModalContent()
    })
  }

  openRegister() {
    this.modeValue = "register"
    this.openModal().then(() => {
      this.updateFormAction()
      this.updateModalContent()
    })
  }

  switchToLogin() {
    this.modeValue = "login"
    this.updateFormAction()
    this.updateModalContent()
  }

  switchToRegister() {
    this.modeValue = "register"
    this.updateFormAction()
    this.updateModalContent()
  }

  openModal() {
    return new Promise((resolve) => {
      const modal = document.getElementById("auth-modal")
      if (modal) {
        // Call the modal's open method properly through Stimulus
        const modalElement = modal.closest('[data-controller*="modal"]') || modal
        
        // Dispatch a click event on the modal element to trigger the controller
        modalElement.style.display = "flex"
        document.addEventListener("keydown", this.handleEscape.bind(this))
        document.body.style.overflow = "hidden"
        
        // Use requestAnimationFrame to ensure DOM updates are complete
        requestAnimationFrame(() => {
          resolve()
        })
      } else {
        resolve()
      }
    })
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.closeModal()
    }
  }

  closeModal() {
    const modal = document.getElementById("auth-modal")
    if (modal) {
      modal.style.display = "none"
      document.removeEventListener("keydown", this.handleEscape.bind(this))
      document.body.style.overflow = ""
    }
  }

  updateFormAction() {
    if (this.hasFormTarget) {
      const isLogin = this.modeValue === "login"
      const action = isLogin ? "/session" : "/users"
      
      this.formTarget.action = action
    }
  }

  updateModalContent() {
    const modal = document.getElementById("auth-modal")
    if (!modal) return
    
    const isLogin = this.modeValue === "login"
    
    // Update title
    const title = modal.querySelector('h3')
    if (title) {
      title.textContent = isLogin ? 'Sign in to Jupiter' : 'Create your Jupiter account'
    }
    
    // Update NationBuilder button text if present
    const oauthButton = modal.querySelector('a[href="/auth/nationbuilder"]')
    if (oauthButton) {
      const nationName = this.getNationDisplayName()
      const buttonText = isLogin ? `Sign in with ${nationName}` : `Sign up with ${nationName}`
      // Update the text content, preserving the SVG
      const textContent = oauthButton.querySelector('svg') ? 
        oauthButton.innerHTML.replace(/Sign (in|up) with .+$/, buttonText) :
        buttonText
      if (oauthButton.querySelector('svg')) {
        // Keep SVG, just update text after it
        const svg = oauthButton.querySelector('svg').outerHTML
        oauthButton.innerHTML = svg + buttonText
      } else {
        oauthButton.textContent = buttonText
      }
    }
    
    // Update primary button text
    const submitButton = modal.querySelector('input[type="submit"]')
    if (submitButton) {
      submitButton.value = isLogin ? 'Sign in' : 'Create account'
    }
    
    // Toggle fields based on mode using data attributes
    const loginFields = modal.querySelectorAll('[data-auth-field="login"]')
    const registerFields = modal.querySelectorAll('[data-auth-field="register"]')
    
    if (isLogin) {
      // Login mode - hide registration fields, show login fields
      registerFields.forEach(field => field.style.display = 'none')
      loginFields.forEach(field => field.style.display = 'flex')
    } else {
      // Register mode - show registration fields, hide login fields  
      registerFields.forEach(field => field.style.display = 'block')
      loginFields.forEach(field => field.style.display = 'none')
    }
    
    // Update switch mode text
    const switchTextContainer = modal.querySelector('.text-sm.text-gray-600')
    if (switchTextContainer) {
      const switchButton = switchTextContainer.querySelector('.font-medium.text-blue-600')
      if (switchButton) {
        const newText = isLogin ? "Don't have an account?" : "Already have an account?"
        const linkText = isLogin ? 'Sign up' : 'Sign in'
        
        // Update the text content
        switchTextContainer.innerHTML = `${newText} <button type="button" class="font-medium text-blue-600 hover:text-blue-500" data-action="click->${isLogin ? 'auth#switchToRegister' : 'auth#switchToLogin'}">${linkText}</button>`
      }
    }
  }

  getNationDisplayName() {
    const slug = this.getNationSlug()
    if (!slug) return "NationBuilder"
    
    return slug.split("-").map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(" ")
  }

  getNationSlug() {
    const metaTag = document.querySelector('meta[name="nationbuilder-slug"]')
    if (metaTag) return metaTag.content
    
    return "nationbuilder"
  }
}