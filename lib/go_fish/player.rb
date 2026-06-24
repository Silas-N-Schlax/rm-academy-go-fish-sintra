require_relative 'book'
require_relative 'card'
# Player class
class Player
  attr_reader :name
  attr_accessor :hand, :books

  def initialize(name = 'Player1')
    @name = name
    @hand = []
    @books = []
  end

  def add_cards(cards)
    cards.each { |card| hand << card }
    create_book_if_possible
  end

  def hand_size
    hand.size
  end

  def take_cards_of_rank(rank)
    find_by_rank = ->(card) { card.rank == rank }

    cards_of_rank = hand.select(&find_by_rank)
    hand.delete_if(&find_by_rank)

    cards_of_rank
  end

  def card?(rank)
    hand.any? { |card| card.rank == rank }
  end

  def empty_hand?
    hand.empty?
  end

  def books_size
    books.size
  end

  def ranks
    all_ranks = []
    hand.map do |card|
      next if all_ranks.include?(card.rank)

      all_ranks << card.rank
    end
    all_ranks.sort_by { |str| Card.value(str) }
  end

  def sort_hand
    hand.sort_by { |card| Card.value(card.rank) }
  end

  def hash
    {
      'name' => name,
      'books' => books.map(&:rank),
      'book_count' => books_size
    }
  end

  private

  def create_book_if_possible
    hand.group_by(&:rank).each do |group|
      card_group = group.last
      create_book_and_remove_cards(group.first) if card_group.length == 4
    end
    books.last
  end

  def create_book_and_remove_cards(book_rank)
    books << Book.new(book_rank)
    take_cards_of_rank(book_rank)
  end
end
