import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput"]

  validateField(event) {
    const field = event.target
    const value = field.value.trim()
    
    // Remove any existing error styling
    field.classList.remove("border-red-300", "text-red-900", "placeholder-red-300")
    field.classList.add("border-gray-300", "text-gray-900", "placeholder-gray-400")
    
    // Basic validation
    if (field.hasAttribute("required") && !value) {
      this.showFieldError(field, "This field is required")
      return false
    }
    
    // Email validation
    if (field.type === "email" && value) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if (!emailRegex.test(value)) {
        this.showFieldError(field, "Please enter a valid email address")
        return false
      }
    }
    
    // Number validation
    if (field.type === "number" && value) {
      const numValue = parseFloat(value)
      if (isNaN(numValue) || numValue <= 0) {
        this.showFieldError(field, "Amount must be a positive number")
        return false
      }
    }
    
    // Date validation
    if (field.type === "date" && value) {
      const selectedDate = new Date(value)
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      
      if (selectedDate > today) {
        this.showFieldError(field, "Date cannot be in the future")
        return false
      }
    }
    
    this.clearFieldError(field)
    return true
  }

  validateFiles(event) {
    const files = event.target.files
    const maxSize = 10 * 1024 * 1024 // 10MB
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf']
    
    for (let file of files) {
      if (file.size > maxSize) {
        this.showFieldError(event.target, `File "${file.name}" is too large. Maximum size is 10MB.`)
        event.target.value = ''
        return false
      }
      
      if (!allowedTypes.includes(file.type)) {
        this.showFieldError(event.target, `File "${file.name}" is not a supported format. Please use PDF, JPG, PNG, or GIF.`)
        event.target.value = ''
        return false
      }
    }
    
    this.clearFieldError(event.target)
    return true
  }

  validateForm(event) {
    let isValid = true
    const form = event.target.closest('form')
    
    // Validate all required fields
    const requiredFields = form.querySelectorAll('[required]')
    requiredFields.forEach(field => {
      if (!this.validateField({ target: field })) {
        isValid = false
      }
    })
    
    // Validate file uploads
    const fileInputs = form.querySelectorAll('input[type="file"]')
    fileInputs.forEach(input => {
      if (input.files.length > 0) {
        if (!this.validateFiles({ target: input })) {
          isValid = false
        }
      }
    })
    
    if (!isValid) {
      event.preventDefault()
      this.scrollToFirstError()
    }
  }

  showFieldError(field, message) {
    field.classList.remove("border-gray-300", "text-gray-900", "placeholder-gray-400")
    field.classList.add("border-red-300", "text-red-900", "placeholder-red-300")
    
    // Find or create error message element
    let errorElement = field.parentNode.querySelector('.text-red-600')
    if (!errorElement) {
      errorElement = document.createElement('p')
      errorElement.className = 'mt-1 text-sm text-red-600'
      field.parentNode.appendChild(errorElement)
    }
    errorElement.textContent = message
  }

  clearFieldError(field) {
    field.classList.remove("border-red-300", "text-red-900", "placeholder-red-300")
    field.classList.add("border-gray-300", "text-gray-900", "placeholder-gray-400")
    
    const errorElement = field.parentNode.querySelector('.text-red-600')
    if (errorElement) {
      errorElement.remove()
    }
  }

  scrollToFirstError() {
    const firstError = this.element.querySelector('.border-red-300')
    if (firstError) {
      firstError.scrollIntoView({ behavior: 'smooth', block: 'center' })
      firstError.focus()
    }
  }
}