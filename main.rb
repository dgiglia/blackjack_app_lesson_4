require 'rubygems'
require 'sinatra'

# Set port for compatability with Nitrous.IO 
configure :development do   
  set :bind, '0.0.0.0'   
  set :port, 3000 
end

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'say_what_now' 

BLACKJACK_AMOUNT = 21
DEALER_HIT_MAX = 17
INITIAL_POCKET = 500

helpers do
  def calculate_total(cards)
    card_faces = cards.map {|card| card[0]}
    total = 0
    card_faces.each do |value|
      if value == "Ace"
        total += 11
      else
        total += (value.to_i == 0 ? 10 : value.to_i)
      end 
    end
    card_faces.select {|val| val == "Ace"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10  
    end
    total
  end
  
  def display_card(card)
    p "<img class='card' src='/images/cards/#{card[1].downcase}_#{card[0].downcase}.jpg'/>"
  end
  
  def dealer_total 
    calculate_total(session[:dealer_cards])
  end
  
  def player_total 
    calculate_total(session[:player_cards])
  end
  
  def winner(msg)
    @show_hit_stay = false
    if session[:pocket] > 0
      @play_again = true
    end
    @winner = "Curse my motherboard, you won, #{session[:player_name]}! #{msg}"
  end

  def loser(msg)
    @show_hit_stay = false
    if session[:pocket] > 0
      @play_again = true
    end
    @loser = "What have we here? Looks like you lost! #{msg}"
  end

  def tie(msg)
    @show_hit_stay = false
    if session[:pocket] > 0
      @play_again = true
    end
    @tie = "Push! It's a tie. #{msg}"
  end

  def show_bet_pocket
    @betinfo = "Your bet was $#{session[:bet]}. You now have $#{session[:pocket]} in your pocket."
  end
end

before do
  @show_hit_stay = true
  @show_dealer_hit = false
  @play_again = false
  @blackjack = false
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/set_name'
  end
end
  
get '/set_name' do
  session[:pocket] = INITIAL_POCKET
  erb :set_name
end

post '/set_name' do
  if params[:player_name].empty?
    @warning = "Name is required. I don't play with strangers."
    halt erb(:set_name)
  end
  session[:player_name] = params[:player_name]
  redirect '/set_bet'
end

get '/set_bet' do
  session[:bet] = nil
  erb :set_bet
end

post '/set_bet' do
  if params[:bet].to_i <= 0 
    @warning = "Ya gotta bet something. What's the fun of beating you if I can't take your money?"
    halt erb(:set_bet)
  elsif params[:bet].to_i > session[:pocket]
    @warning = "Um, yeah, you don't have that kind of money. Let's try something within your budget pal. You've got $#{session[:pocket]}."
    halt erb(:set_bet)
  end
  session[:bet] = params[:bet].to_i
  session[:pocket] -= session[:bet]
  redirect '/game'
end

get '/game' do
  session[:turn] = session[:player_name]
  suits = ['Clubs', 'Hearts', 'Diamonds', 'Spades']
  cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace']
  session[:deck] = cards.product(suits).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  2.times do
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
  end
  if player_total == BLACKJACK_AMOUNT
    @show_hit_stay = false
    redirect '/game/compare'
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  if player_total > BLACKJACK_AMOUNT
    loser("Your total is #{player_total}. BUST!")
    show_bet_pocket
  elsif player_total == BLACKJACK_AMOUNT
    redirect '/game/compare'
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @info = "You have chosen to stay."
  @show_hit_stay = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "Chip"
  @show_hit_stay = false
  if dealer_total > BLACKJACK_AMOUNT
    session[:pocket] += session[:bet] * 2
    winner("Your total was #{player_total}. I busted with #{dealer_total}. Boo hoo.")
    show_bet_pocket
  elsif dealer_total == BLACKJACK_AMOUNT
    loser("I won with #{BLACKJACK_AMOUNT}. Told ya I'd beat you!")
    show_bet_pocket
  elsif dealer_total >= DEALER_HIT_MAX
    redirect '/game/compare'
  elsif dealer_total < DEALER_HIT_MAX
    @show_dealer_hit = true
  end
  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect 'game/dealer'
end

get '/game/compare' do
  @show_hit_stay = false
  session[:turn] = "Chip"
  if (player_total == BLACKJACK_AMOUNT) && (player_total > dealer_total) && (session[:player_cards].count == 2)
    session[:pocket] += session[:bet] * 2.5
    winner("BLACKJACK! How did you do that?")
  elsif (player_total == BLACKJACK_AMOUNT) && (player_total == dealer_total) 
    loser("Our totals were both #{player_total}, but I had BLACKJACK, naturally.")
  elsif player_total < dealer_total
    loser("Your total was #{player_total}. Mine was #{dealer_total}. Did you really think you could beat me?")
  elsif player_total > dealer_total
    session[:pocket] += session[:bet] * 2
    winner("Your total was #{player_total}. Mine was #{dealer_total}. This can't be! We must be in the wrong tube.") 
  elsif player_total == dealer_total
    session[:pocket] += session[:bet]
    tie("Our totals were both #{player_total}. I've been watching too many cat videos. Hit me right in the feels. Couldn't bear to make you sad, little human.")
  end
  show_bet_pocket
  erb :game, layout: false
end

get '/game_over' do
  erb :game_over
end