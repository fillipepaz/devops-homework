class ApplicationController < ActionController::Base
  def hello_world
    render html: "<h2>Hello World</h2>".html_safe
  end
end
