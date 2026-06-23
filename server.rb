require 'sinatra'

require_relative 'lib/go_fish/go_fish_game'
require_relative 'lib/go_fish/player'

class Server < Sinatra::Base

  MIN_GAME_SIZE = 2

  enable :sessions
  def self.game
    @@game ||= GoFishGame.new
  end

  def self.api_keys
    @@api_keys ||= {}
  end

  def self.reset!
    @@game = nil
    @@api_keys = nil
  end

  get '/' do
    return redirect '/game' if self.class.api_keys[session[:api_key]]
    slim :login
  end

  get '/game' do
    return redirect '/' unless self.class.api_keys[session[:api_key]]
    start_game_if_possible
    name = self.class.api_keys[session[:api_key]]
    slim :game, locals: { game: game, current_player: game.find_player(name) }
  end

  post '/join' do
    api_key = Base64.urlsafe_encode64("#{params[:name]}:#{(Time.now.to_f * 1000).to_i}")
    session[:api_key] = api_key
    self.class.api_keys[api_key] = params[:name]
    game.add_player(params[:name])
    redirect '/game'
  end

  private

  def game
    self.class.game
  end

  def start_game_if_possible
    first_player = game.players.first
    return unless first_player.hand_size.zero?
    return unless game.players.size == MIN_GAME_SIZE

    game.start
  end
end



