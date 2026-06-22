require 'sinatra'
require_relative 'lib/go_fish/go_fish_game'
require_relative 'lib/go_fish/player'

class Server < Sinatra::Base
  enable :sessions
  def self.game
    @@game ||= Game.new
  end

  def self.reset!
    @@game = nil
  end
end
