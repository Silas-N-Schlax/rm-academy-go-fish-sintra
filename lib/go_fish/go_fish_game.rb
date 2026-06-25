require_relative 'deck'
require_relative 'card'
require_relative 'turn_result'
# Go Fish Game Class
class GoFishGame
  attr_accessor :deck, :current_player_idx, :results, :players

  SMALL_HAND = 5
  LARGE_HAND = 7
  SMALL_GAME_MAX_SIZE = 2
  LARGE_GAME_MAX_SIZE = 6
  DECK_SIZE = 52

  def initialize(players = [])
    @players = players
    @deck = Deck.new
    @current_player_idx = 0
    @results = []
  end

  def start
    # deck.cards = [Card.new('J'), Card.new('2'), Card.new('K')]
    # players.first.hand = [Card.new('J'), Card.new('J')]
    # players.last.hand = [Card.new('J'), Card.new('K')]
    # ^ For Testing Only
    deck.shuffle_deck
    deal
  end

  def run_turn(player_name, rank)
    return current_player.add_cards([deck.top_card]) if current_player.hand.empty? && !deck.empty?
    return if winner || find_player(player_name).nil?

    handle_turn(player_name, rank)
  end

  def winner
    winning_player if deck.empty? && players.all? { |player| player.empty_hand? }
  end

  def add_player(name)
    players << Player.new(name)
  end

  def game_size
    players.size
  end

  def next_player_turn
    new_index = current_player_idx + 1
    first_player_idx = 0
    self.current_player_idx = new_index > players.size - 1 ? first_player_idx : new_index
  end

  def find_player(name)
    players.select { |player| player.name == name }.first
  end

  def current_player
    players[current_player_idx]
  end

  def started?
    return true unless deck.cards_left == DECK_SIZE

    false
  end

  def list_of_ranks(name)
    find_player(name).ranks
  end

  def list_of_players(current_player)
    all_players = []
    players.map do |player|
      all_players << player.name unless player.name == current_player
    end
    all_players
  end

  def valid_rank?(rank)
    Card.valid_rank?(rank)
  end

  def card?(rank)
    current_player.card?(rank)
  end

  def turn_skipped?
    deck.empty? && current_player.empty_hand?
  end

  def latest_result
    results.last
  end

  def as_json(name)
    current_player = find_player(name)
    {
      'turn_index' => current_player_idx,
      'players' => players.map(&:hash),
      'hand' => current_player.hand.map(&:hash),
      'round_results' => results.map { |result| result.hash(current_player.name) },
      'winners' => winner ? [winning_player] : []
    }
  end

  private

  def handle_turn(player_name, rank)
    current_player = self.current_player
    player_in_question = find_player(player_name)
    cards = player_in_question.take_cards_of_rank(rank)

    current_player.add_cards(cards) unless cards.empty?
    fishing_card = go_fish(rank) if cards.empty?
    generate_turn_result(player_in_question, rank, cards, fishing_card, current_player)
  end

  def deal
    number_of_cards_to_deal.times do
      players.each do |player|
        player.add_cards([deck.top_card])
      end
    end
  end

  def go_fish(rank)
    card = deck.top_card
    return next_player_turn if card.nil?

    current_player.add_cards([card])
    next_player_turn unless card.rank == rank
    card
  end

  def generate_turn_result(opponent, rank, cards, card_picked_up, current_player)
    results << TurnResult.new(
      current_player: current_player, opponent: opponent,
      card_asked_for: rank, cards_taken: cards,
      card_picked_up: card_picked_up, goes_again: cards.empty? && card_picked_up.nil?
    )
  end

  def winning_player
    winning_players = []
    players.each do |player|
      winning_players << player if winning_players.empty? || winning_players.first.books_size == player.books_size
      winning_players = [player] if player.books_size > winning_players.first.books_size
    end
    return player_highest_book_value(winning_players) if winning_players.size > 1

    winning_players.first
  end

  def player_highest_book_value(tied_players)
    current_winner = [nil, nil]
    tied_players.each do |player|
      player.books.each do |book|
        current_winner = [player, book] if current_winner[1].nil? || book.value > current_winner[1].value
      end
    end
    current_winner.first
  end

  def number_of_cards_to_deal
    return LARGE_HAND if players.size <= SMALL_GAME_MAX_SIZE

    SMALL_HAND if players.size > SMALL_GAME_MAX_SIZE
  end
end
