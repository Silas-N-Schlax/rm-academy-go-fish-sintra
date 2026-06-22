require_relative 'book'
# Player class
class Player
  attr_reader :user
  attr_accessor :hand, :books

  def initialize(user)
    @user = user
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

  def format_hand
    message_ary = ["#{user.name}, you have the following cards in your hand:"]
    hand.each do |card|
      message_ary << "- #{card}"
    end
    message_ary
  end

  def formatted_player_details
    "Cards: #{hand_size} | Books: #{books_size}"
  end

  def format_books
    message_ary = ['Books:']
    books.each do |book|
      message_ary << "- #{book}s"
    end
    message_ary
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
