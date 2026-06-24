require 'sinatra'

require_relative 'lib/go_fish/go_fish_game'
require_relative 'lib/go_fish/player'
# Server class + Sinatra App
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
    return redirect '/game' if authenticated?

    slim :login
  end

  get '/game' do
    return redirect '/' unless authenticated?
    return redirect '/game-over' if game.winner

    start_game_if_possible
    slim :game, locals: { game: game, current_player: game.find_player(current_player_name) }
  end

  post '/join' do
    api_key = Base64.urlsafe_encode64("#{params[:name]}:#{Time.new.to_f}")
    session[:api_key] = api_key
    self.class.api_keys[api_key] = params[:name]
    game.add_player(params[:name])
    redirect '/game'
  end

  get '/wrong-turn' do
    slim :wrong_turn
  end

  get '/game-over' do
    self.class.reset!

    slim :game_over
  end

  post '/ask' do
    return redirect '/' unless authenticated?
    return redirect '/game' unless game.started?

    return redirect '/wrong-turn' unless current_player_name == game.current_player.name

    game.run_turn(params[:players], params[:ranks])
    redirect '/game'
  end

  private

  def authenticated?
    return true if current_player_name

    false
  end

  def current_player_name
    self.class.api_keys[session[:api_key]]
  end

  def game
    self.class.game
  end

  def start_game_if_possible
    return if game.started?
    return unless game.players.size == MIN_GAME_SIZE

    game.start
  end
end
