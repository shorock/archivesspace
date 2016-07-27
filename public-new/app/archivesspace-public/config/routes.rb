Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/', to: 'index#index'
  get '/welcome', to: 'welcome#show'
  get "repositories/:id" => 'repositories#show'
  get '/repositories', to: 'repositories#index'
  get '/search', to: 'search#search'
end
