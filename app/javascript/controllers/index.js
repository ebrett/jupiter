// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Import specific controllers
import OauthErrorController from "./oauth_error_controller"
import ModalController from "./modal_controller"

// Register controllers
application.register("oauth-error", OauthErrorController)
application.register("modal", ModalController)

eagerLoadControllersFrom("controllers", application)
