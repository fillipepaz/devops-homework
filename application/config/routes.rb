Rails.application.routes.draw do
  match '*path', to: 'application#hello_world', via: :all
  root 'application#hello_world'
end
