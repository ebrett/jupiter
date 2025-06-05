require 'capybara/rspec'
require 'capybara/rails'

# Configure Capybara for system tests
RSpec.configure do |config|
  config.include Capybara::DSL, type: :system
  config.include Capybara::RSpecMatchers, type: :system
  
  # Use Rack::Test driver by default for faster tests
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
  
  # Use Selenium Chrome for JavaScript tests
  config.before(:each, type: :system, js: true) do
    driven_by :selenium, using: :headless_chrome
  end
end

# Configure Capybara defaults
Capybara.default_max_wait_time = 5
Capybara.disable_animation = true

# Register Chrome driver for JavaScript tests
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-gpu')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end