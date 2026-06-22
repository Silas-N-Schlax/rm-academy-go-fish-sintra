require_relative 'player'
# User class
class User
  attr_accessor :name, :name_message
  attr_reader :client, :id

  def initialize(client, id)
    @client = client
    @id = id
  end

  def player
    @player ||= Player.new(self)
  end

  def to_s
    "#{name} - (#{id})"
  end
end
