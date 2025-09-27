require './app'

# Middleware to handle any host
class HostNameMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Use the actual host from the request headers, fallback to a valid hostname if not present
    host = env["HTTP_HOST"] || env["SERVER_NAME"] || "localhost"
    
    # Ensure the host is valid according to Rack::Lint requirements
    # Strip any port number if present
    host = host.split(":").first
    
    # Set the SERVER_NAME to the cleaned host
    env["SERVER_NAME"] = host
    
    @app.call(env)
  end
end

# Use the middleware
use HostNameMiddleware
run App
