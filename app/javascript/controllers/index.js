// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

console.log("Loading Stimulus controllers...")

// Automatically load all controllers
eagerLoadControllersFrom("controllers", application)

console.log("Stimulus application:", application)
