require_relative 'card'

# Deck
class Deck
  attr_accessor :cards

  def initialize
    @cards = Card::SUITS.flat_map do |suit|
      Card::RANKS.map do |rank|
        Card.new(rank, suit)
      end
    end
  end

  def top_card
    cards.shift
  end

  def shuffle_deck
    new_deck = cards.dup.shuffle!
    shuffle_deck if new_deck == cards

    self.cards = new_deck
  end

  def cards_left
    cards.size
  end

  def empty?
    cards.empty?
  end
end
