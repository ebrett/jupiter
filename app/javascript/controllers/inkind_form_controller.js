import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  validateField(event) {
    const field = event.target
    const fieldName = field.name
    const value = field.value.trim()
    
    // Clear previous validation styling
    this.clearFieldErrors(field)
    
    // Validate based on field type
    let isValid = true
    let errorMessage = ""
    
    switch(true) {
      case fieldName.includes('donor_name'):
        isValid = this.validateRequired(value) && this.validateMaxLength(value, 255)
        if (!isValid) errorMessage = "Donor name is required and must be under 255 characters"
        break
        
      case fieldName.includes('donor_email'):
        isValid = this.validateRequired(value) && this.validateEmail(value)
        if (!isValid) errorMessage = "Please enter a valid email address"
        break
        
      case fieldName.includes('donor_address'):
        isValid = this.validateRequired(value) && this.validateMaxLength(value, 500)
        if (!isValid) errorMessage = "Donor address is required and must be under 500 characters"
        break
        
      case fieldName.includes('donation_type'):
        isValid = this.validateRequired(value) && ['Goods', 'Services'].includes(value)
        if (!isValid) errorMessage = "Please select a valid donation type"
        break
        
      case fieldName.includes('expense_category_code'):
        isValid = this.validateRequired(value)
        if (!isValid) errorMessage = "Please select an expense category"
        break
        
      case fieldName.includes('amount_requested'):
        isValid = this.validateRequired(value) && this.validatePositiveNumber(value)
        if (!isValid) errorMessage = "Amount must be a positive number"
        break
        
      case fieldName.includes('donation_date'):
        isValid = this.validateRequired(value) && this.validateDateNotFuture(value)
        if (!isValid) errorMessage = "Donation date is required and cannot be in the future"
        break
        
      case fieldName.includes('item_description'):
        isValid = this.validateRequired(value) && this.validateMaxLength(value, 1000)
        if (!isValid) errorMessage = "Item description is required and must be under 1000 characters"
        break
    }
    
    // Apply validation styling
    if (!isValid) {
      this.showFieldError(field, errorMessage)
    }
    
    return isValid
  }
  
  validateForm(event) {
    let isFormValid = true
    const form = event.target.closest('form')
    
    // Validate all required fields
    const requiredFields = form.querySelectorAll('[required]')
    requiredFields.forEach(field => {
      const fieldEvent = { target: field }
      if (!this.validateField(fieldEvent)) {
        isFormValid = false
      }
    })
    
    if (!isFormValid) {
      event.preventDefault()
      this.showFormError("Please correct the errors above before submitting.")
    }
    
    return isFormValid
  }
  
  // Validation helper methods
  validateRequired(value) {
    return value && value.length > 0
  }
  
  validateEmail(value) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(value)
  }
  
  validateMaxLength(value, maxLength) {
    return value.length <= maxLength
  }
  
  validatePositiveNumber(value) {
    const num = parseFloat(value)
    return !isNaN(num) && num > 0
  }
  
  validateDateNotFuture(value) {
    const inputDate = new Date(value)
    const today = new Date()
    today.setHours(23, 59, 59, 999) // End of today
    return inputDate <= today
  }
  
  // UI helper methods
  clearFieldErrors(field) {
    // Remove error classes
    field.classList.remove('border-red-300', 'text-red-900', 'placeholder-red-300', 'focus:border-red-500', 'focus:ring-red-500')
    field.classList.add('border-gray-300', 'focus:border-blue-500', 'focus:ring-blue-500')
    
    // Remove error message
    const errorElement = field.parentElement.querySelector('.text-red-600')
    if (errorElement && errorElement.dataset.clientValidation) {
      errorElement.remove()
    }
  }
  
  showFieldError(field, message) {
    // Add error classes
    field.classList.remove('border-gray-300', 'focus:border-blue-500', 'focus:ring-blue-500')
    field.classList.add('border-red-300', 'text-red-900', 'placeholder-red-300', 'focus:border-red-500', 'focus:ring-red-500')
    
    // Add error message if it doesn't exist
    let errorElement = field.parentElement.querySelector('.text-red-600[data-client-validation]')
    if (!errorElement) {
      errorElement = document.createElement('p')
      errorElement.className = 'mt-1 text-sm text-red-600'
      errorElement.dataset.clientValidation = 'true'
      field.parentElement.appendChild(errorElement)
    }
    errorElement.textContent = message
  }
  
  showFormError(message) {
    // Scroll to top to show any existing error summary
    window.scrollTo({ top: 0, behavior: 'smooth' })
    
    // You could also create a toast notification here
    console.warn("Form validation error:", message)
  }
}