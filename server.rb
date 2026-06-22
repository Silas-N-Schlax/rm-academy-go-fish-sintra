require 'sinatra'

require_relative 'lib/go_fish/go_fish_game'
require_relative 'lib/go_fish/player'

class Server < Sinatra::Base
  enable :sessions
  def self.game
    @@game ||= Game.new
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
    session_name = self.class.api_keys[session[:api_key]]
    slim :game, locals: { name: session_name }
  end

  post '/join' do
    api_key = Base64.urlsafe_encode64("#{params[:name]}:#{(Time.now.to_f * 1000).to_i}")
    session[:api_key] = api_key
    self.class.api_keys[api_key] = params[:name]
    redirect '/game'
  end
end

