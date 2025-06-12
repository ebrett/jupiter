# frozen_string_literal: true

Rails.application.configure do
  config.view_component.preview_paths << Rails.root.join("spec/components/previews")
  config.view_component.preview_controller = "ApplicationController"

  # Ensure components are loaded in development
  config.view_component.show_previews = Rails.env.development?

  # Generate helpful error messages in test/development
  config.view_component.render_monkey_patch_enabled = Rails.env.test? || Rails.env.development?
end
