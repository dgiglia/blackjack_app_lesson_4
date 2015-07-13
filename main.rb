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
  if session[:player_name]
    redirect '/game'
  else
    redirect '/set_name'
  end
end
  
get '/set_name' do
  erb :set_name
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  suits = ['Clubs', 'Hearts', 'Diamonds', 'Spades']
  cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace']
  session[:deck] = cards.product(suits).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  erb :game
end