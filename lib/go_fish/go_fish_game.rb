require_relative 'deck'
require_relative 'card'
require_relative 'turn_result'
# Go Fish Game Class
class GoFishGame
  attr_accessor :deck, :current_user_idx, :results
  attr_reader :users

  SMALL_HAND = 5
  LARGE_HAND = 7
  SMALL_GAME_MAX_SIZE = 2
  LARGE_GAME_MAX_SIZE = 6

  def initialize(users)
    @users = users
    @deck = Deck.new
    @current_user_idx = 0
    @results = []
  end

  def start
    # deck.cards = [Card.new('J')]
    # users.first.player.hand = [Card.new('J'), Card.new('J')]
    # users.last.player.hand = [Card.new('J')]
    # ^ For Testing Server and Sockets Only
    deck.shuffle_deck
    deal
  end

  def run_turn(user_id, rank)
    return if winner || find_user(user_id).nil?

    current_user = self.current_user
    user_in_question = find_user(user_id)
    cards = user_in_question.player.take_cards_of_rank(rank)

    current_user.player.add_cards(cards) unless cards.empty?
    fishing_card = go_fish(rank) if cards.empty?
    generate_turn_result(user_in_question, rank, cards, fishing_card, current_user)
  end

  def winner
    winning_user if deck.empty? && users.all? { |user| user.player.empty_hand? }
  end

  def next_user_turn
    new_index = current_user_idx + 1
    first_user_idx = 0
    self.current_user_idx = new_index > users.size - 1 ? first_user_idx : new_index
  end

  def find_user(id)
    users.select { |user| user.id == id }.first
  end

  def current_user
    users[current_user_idx]
  end

  def latest_result
    results.last
  end

  def valid_rank?(rank)
    Card.valid_rank?(rank)
  end

  def card?(rank)
    current_user.player.card?(rank)
  end

  def turn_skipped?
    deck.empty? && current_user.player.empty_hand?
  end

  private

  def deal
    number_of_cards_to_deal.times do
      users.each do |user|
        user.player.add_cards([deck.top_card])
      end
    end
  end

  def go_fish(rank)
    card = deck.top_card
    return next_user_turn if card.nil?

    current_user.player.add_cards([card])
    next_user_turn unless card.rank == rank
    card
  end

  def generate_turn_result(opponent, rank, cards, card_picked_up, current_user)
    results << TurnResult.new(
      current_user: current_user, opponent: opponent,
      card_asked_for: rank, cards_taken: cards,
      card_picked_up: card_picked_up, goes_again: cards.empty? && card_picked_up.nil?
    )
  end

  def winning_user
    winning_users = []
    users.each do |user|
      winning_users << user if winning_users.empty? || winning_users.first.player.books_size == user.player.books_size
      winning_users = [user] if user.player.books_size > winning_users.first.player.books_size
    end
    return player_highest_book_value(winning_users) if winning_users.size > 1

    winning_users.first
  end

  def player_highest_book_value(tied_users)
    current_winner = [nil, nil]
    tied_users.each do |user|
      user.player.books.each do |book|
        current_winner = [user, book] if current_winner[1].nil? || book.value > current_winner[1].value
      end
    end
    current_winner.first
  end

  def number_of_cards_to_deal
    return LARGE_HAND if users.size <= SMALL_GAME_MAX_SIZE

    SMALL_HAND if users.size > SMALL_GAME_MAX_SIZE
  end
end
