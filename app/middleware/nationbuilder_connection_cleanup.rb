# Middleware to clean up NationBuilder HTTP connections after each request
class NationbuilderConnectionCleanup
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  ensure
    # Clean up any persistent HTTP connections
    NationbuilderApiClient.cleanup_connections if defined?(NationbuilderApiClient)
  end
end
