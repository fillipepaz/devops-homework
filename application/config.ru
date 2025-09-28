# This file is used by Rack-based servers to start the application.

# Disable Rack::Lint in development
ENV['RACK_ENV'] = 'production'

app = lambda do |env|
  [
    200,
    {'Content-Type' => 'text/html'},
    ['<!DOCTYPE html><html><head><title>Hello World</title></head><body><h2>Hello World</h2></body></html>']
  ]
end

use Rack::ContentLength
run app
