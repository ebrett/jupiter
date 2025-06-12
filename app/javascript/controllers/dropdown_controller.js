import { Controller } from "@hotwired/stimulus"

console.log("Dropdown controller loaded")

export default class extends Controller {
  static targets = ["button", "menu"]
  static classes = ["hidden"]

  connect() {
    console.log("Dropdown controller connected to element:", this.element)
    this.isOpen = false
    
    // Set initial ARIA state
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
      console.log("Button target found:", this.buttonTarget)
    } else {
      console.log("No button target found")
    }
    
    if (this.hasMenuTarget) {
      console.log("Menu target found:", this.menuTarget)
    } else {
      console.log("No menu target found")
    }
  }

  toggle(event) {
    console.log("Toggle method called", event)
    event.preventDefault()
    event.stopPropagation()
    
    if (this.isOpen) {
      console.log("Closing dropdown")
      this.close()
    } else {
      console.log("Opening dropdown")
      this.open()
    }
  }

  open() {
    console.log("Opening dropdown, menu target:", this.menuTarget)
    this.menuTarget.classList.remove("hidden")
    this.isOpen = true
    this.buttonTarget.setAttribute("aria-expanded", "true")
    
    // Focus the first menu item
    this.focusFirstItem()
  }

  close() {
    console.log("Closing dropdown")
    this.menuTarget.classList.add("hidden")
    this.isOpen = false
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.buttonTarget.focus()
  }

  closeOnClickOutside(event) {
    if (this.isOpen && !this.element.contains(event.target)) {
      this.close()
    }
  }

  selectItem(event) {
    // If it's a link, let it navigate naturally
    if (event.target.tagName === "A" || event.target.closest("a")) {
      this.close()
      return
    }
    
    // If it's a button, close the dropdown
    this.close()
  }

  focusFirstItem() {
    const firstItem = this.menuTarget.querySelector('a, button:not([disabled])')
    if (firstItem) {
      firstItem.focus()
    }
  }

  // Keyboard navigation
  keydown(event) {
    if (!this.isOpen) return

    const items = Array.from(this.menuTarget.querySelectorAll('a, button:not([disabled])'))
    const currentIndex = items.indexOf(document.activeElement)

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        const nextIndex = currentIndex < items.length - 1 ? currentIndex + 1 : 0
        items[nextIndex]?.focus()
        break
      
      case "ArrowUp":
        event.preventDefault()
        const prevIndex = currentIndex > 0 ? currentIndex - 1 : items.length - 1
        items[prevIndex]?.focus()
        break
      
      case "Home":
        event.preventDefault()
        items[0]?.focus()
        break
      
      case "End":
        event.preventDefault()
        items[items.length - 1]?.focus()
        break
      
      case "Enter":
      case " ":
        if (document.activeElement !== this.buttonTarget) {
          event.preventDefault()
          document.activeElement.click()
        }
        break
      
      case "Escape":
        event.preventDefault()
        this.close()
        break
    }
  }
}