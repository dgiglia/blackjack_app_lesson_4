require 'rubygems'
require 'sinatra'

# Set port for compatability with Nitrous.IO 
configure :development do   
  set :bind, '0.0.0.0'   
  set :port, 3000 
end

set :sessions, true

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'what_is_going_on' 

get '/' do
  erb :set_name
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  session[:deck] = [['2', 'D'], ['3', 'D']]
  session[:player_cards] = []
  session[:player_cards] << session[:deck].pop 
  erb :game
end