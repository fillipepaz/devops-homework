class HomeController < ApplicationController
  def index
    render html: "<h2>Hello World</h2>".html_safe
  end
end
