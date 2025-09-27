require './app'

# Middleware to handle any host
class HostNameMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Set a default SERVER_NAME if none is provided
    env["SERVER_NAME"] = "localhost" if env["SERVER_NAME"].nil? || env["SERVER_NAME"].empty?
    
    # Always allow the request to proceed regardless of host
    # For production, the recommended approach is define a more restrictive policy.
    @app.call(env)
  end
end

# Use the middleware
use HostNameMiddleware
run App
