require 'sinatra/base'

class App < Sinatra::Base

  before do
    pass if request.path_info == '/'
    redirect to('/')
  end

  get '/' do
    '<h2>Hello World</h2>'
  end

  run! if app_file == $0
end
