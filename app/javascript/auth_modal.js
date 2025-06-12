// Global functions for auth modal
window.showAuthModal = function(mode = 'login') {
  console.log('showAuthModal called with mode:', mode)
  const modal = document.getElementById("auth-modal")
  if (modal) {
    console.log('Modal found, showing...')
    
    // Update the modal content based on mode
    window.updateModalMode(mode)
    
    // Show the modal
    modal.style.display = "flex"
    document.body.style.overflow = "hidden"
    
    // Add close functionality
    const closeButton = modal.querySelector('[data-action*="modal#close"]')
    if (closeButton) {
      closeButton.onclick = () => window.closeAuthModal()
    }
    
    // Close on escape and backdrop
    const escapeHandler = (e) => {
      if (e.key === 'Escape') {
        window.closeAuthModal()
        document.removeEventListener('keydown', escapeHandler)
      }
    }
    document.addEventListener('keydown', escapeHandler)
    
    modal.onclick = (e) => {
      if (e.target === modal) window.closeAuthModal()
    }
    
    // Add mode switching handlers
    const switchButton = modal.querySelector('[data-action*="switchTo"]')
    if (switchButton) {
      switchButton.onclick = (e) => {
        e.preventDefault()
        const newMode = mode === 'login' ? 'register' : 'login'
        window.updateModalMode(newMode)
      }
    }
  } else {
    console.error('Auth modal not found')
  }
}

window.updateModalMode = function(mode) {
  const modal = document.getElementById("auth-modal")
  if (!modal) return
  
  // Update title
  const title = modal.querySelector('h3')
  if (title) {
    title.textContent = mode === 'login' ? 'Sign in to Jupiter' : 'Create your Jupiter account'
  }
  
  // Update form action
  const form = modal.querySelector('form')
  if (form) {
    form.action = mode === 'login' ? '/session' : '/users'
  }
  
  // Update NationBuilder button text
  const oauthButton = modal.querySelector('a[href="/auth/nationbuilder"]')
  if (oauthButton) {
    const buttonText = mode === 'login' ? 'Sign in with NationBuilder' : 'Sign up with NationBuilder'
    const textNode = oauthButton.childNodes[oauthButton.childNodes.length - 1]
    if (textNode) {
      textNode.textContent = buttonText
    }
  }
  
  // Update primary button text
  const submitButton = modal.querySelector('input[type="submit"]')
  if (submitButton) {
    submitButton.value = mode === 'login' ? 'Sign in' : 'Create account'
  }
  
  // Toggle registration-only fields
  const nameFields = modal.querySelector('.grid.grid-cols-2')
  const passwordConfirm = modal.querySelector('input[name="password_confirmation"]')?.closest('div')
  const rememberMe = modal.querySelector('input[name="remember_me"]')?.closest('div')
  const forgotPassword = modal.querySelector('a[href*="password"]')?.closest('div')
  const terms = modal.querySelector('.text-xs.text-gray-500')?.closest('div')
  
  if (mode === 'register') {
    if (nameFields) nameFields.style.display = 'block'
    if (passwordConfirm) passwordConfirm.style.display = 'block'
    if (rememberMe) rememberMe.style.display = 'none'
    if (forgotPassword) forgotPassword.style.display = 'none'
    if (terms) terms.style.display = 'block'
  } else {
    if (nameFields) nameFields.style.display = 'none'
    if (passwordConfirm) passwordConfirm.style.display = 'none'
    if (rememberMe) rememberMe.style.display = 'flex'
    if (forgotPassword) forgotPassword.style.display = 'block'
    if (terms) terms.style.display = 'none'
  }
  
  // Update switch mode text
  const switchText = modal.querySelector('.text-sm.text-gray-600')
  if (switchText) {
    const newText = mode === 'login' ? "Don't have an account?" : "Already have an account?"
    switchText.childNodes[0].textContent = newText + ' '
  }
  
  const switchLink = modal.querySelector('.font-medium.text-blue-600')
  if (switchLink) {
    switchLink.textContent = mode === 'login' ? 'Sign up' : 'Sign in'
    switchLink.onclick = (e) => {
      e.preventDefault()
      const newMode = mode === 'login' ? 'register' : 'login'
      window.updateModalMode(newMode)
    }
  }
}

window.closeAuthModal = function() {
  const modal = document.getElementById("auth-modal")
  if (modal) {
    modal.style.display = "none"
    document.body.style.overflow = ""
  }
}