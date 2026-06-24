require 'sinatra'
require 'sinatra/contrib/all'
require 'rack/contrib'
require_relative 'lib/go_fish/go_fish_game'
require_relative 'lib/go_fish/player'
# Server class + Sinatra App
class Server < Sinatra::Base
  MIN_GAME_SIZE = 2

  register Sinatra::RespondWith
  use Rack::JSONBodyParser

  enable :sessions
  # set :bind, '0.0.0.0'
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
    return redirect_to('/game') if authenticate!

    slim :login, locals: { errors: nil }
  end

  get '/game' do
    return redirect_to('/') unless authenticate!
    return redirect_to('/game-over') if game.winner

    start_game_if_possible
    respond_to do |f|
      f.html { slim :game, locals: { game: game, current_player: game.find_player(current_player_name) } }
      f.json { json game.as_json(current_json_player_name) }
    end
  end

  post '/join' do
    name = params[:name] || JSON.parse(request.body.read)['name']
    return redirect '/wrong-name' unless name_valid?(name)

    api_key = Base64.urlsafe_encode64("#{name}:#{Time.new.to_f}")
    session[:api_key] = api_key
    self.class.api_keys[api_key] = name
    game.add_player(name)

    respond_to do |f|
      f.html { redirect 'game' }
      f.json { { 'api_key' => api_key }.to_json }
    end
  end

  get '/wrong-name' do
    slim :login, locals: { errors: ['That name is already taken'] }
  end

  get '/wrong-turn' do
    slim :wrong_turn
  end

  get '/game-over' do
    self.class.reset!

    slim :game_over
  end

  post '/game' do
    return redirect_to('/') unless authenticate!
    return redirect_to('/game') unless game.started?

    name = current_player_name || current_json_player_name
    return redirect('/wrong-turn') unless name == game.current_player.name

    game.run_turn(player, rank)
    respond_to do |f|
      f.html { redirect '/game' }
      f.json { json game.as_json(current_json_player_name) }
    end
  end

  private

  def authenticate!
    return api_auth? if auth.provided?

    web_auth?

    # auth = Rack::Auth::Basic::Request.new(request.env)

    # return nil unless auth.provided? && auth.basic?

    # api_keys = auth.username
  end

  def redirect_to(path)
    respond_to do |f|
      f.html { redirect path }
      f.json { halt 400 }
    end
  end

  def api_auth?
    halt 401 unless api_keys[auth.username]
    true
  end

  def web_auth?
    return true if current_player_name

    false
  end

  def auth
    Rack::Auth::Basic::Request.new(request.env)
  end

  def player
    return params[:players] if params[:players]

    params[:player]
  end

  def rank
    return params[:ranks] if params[:ranks]

    params[:rank]
  end

  def name_valid?(name)
    return false if name.empty?
    return false if api_keys.values.include?(name)

    true
  end

  def current_player_name
    api_keys[session[:api_key]]
    # ! Shorten with api_keys method
  end

  def current_json_player_name
    api_keys[auth.username]
  end

  def game
    self.class.game
  end

  def api_keys
    self.class.api_keys
  end

  def start_game_if_possible
    return if game.started?
    return unless game.players.size == MIN_GAME_SIZE

    game.start
  end
end
