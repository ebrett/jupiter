require 'capybara/rspec'
require 'selenium/webdriver'

# Configure Capybara to use Selenium with Chrome
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-web-security')
  options.add_argument('--allow-running-insecure-content')
  options.add_argument('--disable-features=VizDisplayCompositor')
  # Disable macOS malware/security dialogs
  options.add_argument('--disable-background-timer-throttling')
  options.add_argument('--disable-backgrounding-occluded-windows')
  options.add_argument('--disable-renderer-backgrounding')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Configure Capybara to use Selenium with headless Chrome (default for CI)
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-web-security')
  options.add_argument('--allow-running-insecure-content')
  options.add_argument('--disable-features=VizDisplayCompositor')
  options.add_argument('--window-size=1920,1080')

  # Performance optimizations for faster startup
  options.add_argument('--disable-extensions')
  options.add_argument('--disable-plugins')
  options.add_argument('--disable-images')
  options.add_argument('--disable-default-apps')
  options.add_argument('--disable-sync')
  options.add_argument('--disable-translate')
  options.add_argument('--hide-scrollbars')
  options.add_argument('--metrics-recording-only')
  options.add_argument('--mute-audio')
  options.add_argument('--no-first-run')
  options.add_argument('--safebrowsing-disable-auto-update')
  options.add_argument('--disable-ipc-flooding-protection')
  # Keep JavaScript enabled for tests to work

  # Disable macOS malware/security dialogs
  options.add_argument('--disable-background-timer-throttling')
  options.add_argument('--disable-backgrounding-occluded-windows')
  options.add_argument('--disable-renderer-backgrounding')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Set the default driver based on environment
# Use headless by default, but allow headed mode for debugging
if ENV['HEADED']
  Capybara.default_driver = :selenium_chrome
  Capybara.javascript_driver = :selenium_chrome
else
  Capybara.default_driver = :selenium_chrome_headless
  Capybara.javascript_driver = :selenium_chrome_headless
end

# Configure Capybara settings
Capybara.configure do |config|
  # Reduced wait time for faster tests (was 5s)
  config.default_max_wait_time = 2
  config.ignore_hidden_elements = true
  config.server = :puma, { Silent: true }
  config.server_host = 'localhost'
  config.server_port = 9887 + ENV['TEST_ENV_NUMBER'].to_i
  config.app_host = "http://#{config.server_host}:#{config.server_port}"

  # Performance optimizations
  config.enable_aria_label = true
  config.disable_animation = true if config.respond_to?(:disable_animation)
end

# Configure screenshot settings
Capybara.save_path = Rails.root.join('tmp', 'capybara')
Capybara.asset_host = 'http://localhost:3000'

# Ensure screenshot directory exists
FileUtils.mkdir_p(Capybara.save_path) unless File.directory?(Capybara.save_path)

# RSpec configuration for system tests
RSpec.configure do |config|
  # Rails 8 handles database transactions automatically for system tests
  # by using a separate database connection that shares data via a shared connection

  # Enhanced screenshot and debugging on failure
  config.after(:each, type: :system) do |example|
    if example.exception
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      test_name = example.full_description.parameterize(separator: '_')[0..80]
      screenshot_name = "failure_#{test_name}_#{timestamp}.png"

      # Take screenshot
      save_screenshot(screenshot_name)

      # Save page HTML for debugging
      html_name = "failure_#{test_name}_#{timestamp}.html"
      File.write(File.join(Capybara.save_path, html_name), page.html)

      # Log useful debugging information
      puts "\n" + "="*80
      puts "SYSTEM TEST FAILURE: #{example.full_description}"
      puts "="*80
      puts "Screenshot: #{Capybara.save_path}/#{screenshot_name}"
      puts "HTML dump: #{Capybara.save_path}/#{html_name}"
      puts "Current URL: #{current_url}"
      puts "Page title: #{page.title}" rescue nil

      # Log browser console errors if available (Chrome only)
      if Capybara.current_driver.to_s.include?('chrome')
        begin
          logs = page.driver.browser.logs.get(:browser)
          if logs.any?
            puts "Browser console errors:"
            logs.each { |log| puts "  #{log.level}: #{log.message}" }
          end
        rescue => e
          # Ignore if browser logs aren't available
        end
      end

      puts "="*80 + "\n"
    end
  end

  # Clean up old screenshots periodically (keep last 50)
  config.before(:suite) do
    if File.directory?(Capybara.save_path)
      screenshots = Dir[File.join(Capybara.save_path, 'failure_*.png')].sort
      html_files = Dir[File.join(Capybara.save_path, 'failure_*.html')].sort

      # Keep only the 50 most recent files
      (screenshots[0...-50] + html_files[0...-50]).each { |file| File.delete(file) rescue nil }
    end
  end
end
