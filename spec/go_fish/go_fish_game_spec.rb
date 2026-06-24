require_relative '../../lib/go_fish/card'
require_relative '../../lib/go_fish/go_fish_game'
require_relative '../../lib/go_fish/book'
require_relative '../../lib/go_fish/turn_result'

describe GoFishGame do
  let(:player1) { Player.new('player1') }
  let(:player2) { Player.new('player2') }
  describe '#start' do
    context 'when a game is started with two players' do
      let(:game) { described_class.new([player1, player2]) }
      let(:game_player1) { game.players.first }
      let(:game_player2) { game.players.last }
      before { game.start }
      it 'deals 7 cards to each player' do
        expected_hand_size = 7
        game.players.each do |player|
          expect(player.hand_size).to eq expected_hand_size
        end
      end
      it 'cards are not in order' do
        default_hand1 = [Card.new('2'), Card.new('4'), Card.new('6'), Card.new('8'), Card.new('10')]
        default_hand2 = [Card.new('3'), Card.new('5'), Card.new('7'), Card.new('9'), Card.new('J')]
        expect(game_player1.hand).to_not eq default_hand1
        expect(game_player2.hand).to_not eq default_hand2
        expect(game_player1.hand).to_not be_empty
        expect(game_player2.hand).to_not be_empty
      end
    end
    context 'when a game is started with 4 players' do
      let(:player3) { Player.new('player3') }
      let(:player4) { Player.new('player4') }
      let(:game) { described_class.new([player1, player2, player3, player4]) }
      before { game.start }
      it 'deals 5 cards to each player' do
        expected_hand_size = 5
        game.players.each do |player|
          expect(player.hand_size).to eq expected_hand_size
        end
      end
    end
  end
  describe '#current_player' do
    let(:game) { described_class.new([player1, player2]) }
    it 'returns the current player' do
      expect(game.current_player).to eq player1
    end
  end

  describe '#find_player' do
    let(:game) { described_class.new([player1, player2]) }
    context 'when provided with id for player1' do
      it 'returns player1' do
        player1_name = 'player1'
        result = game.find_player(player1_name)
        expect(result.name).to eq player1.name
      end
    end

    context 'when provided with an id for a non-existent player' do
      it 'returns nil' do
        player3_name = 'player3'
        result = game.find_player(player3_name)
        expect(result).to be_nil
      end
    end
  end

  describe '#add_player' do
    context 'when a new player is added' do
      let(:game) { described_class.new }
      let(:name) { 'Player1' }
      it 'creates a new player instance' do
        expect(game.add_player(name).first).to be_a Player
      end

      it 'adds player to players array' do
        game.add_player(name)
        expected_game_size = 1
        expect(game.game_size).to eq expected_game_size
      end
    end

    context 'when two players are added' do
      let(:game) { described_class.new }
      before do
        game.add_player('Player1')
        game.add_player('Player2')
      end

      it 'two players are added to game' do
        expected_game_size = 2
        expect(game.game_size).to eq expected_game_size
      end
    end
  end

  describe '#game_size' do
    let(:game) { described_class.new }
    it 'returns 0 when no there are no players' do
      expect(game.game_size).to be_zero
    end

    it 'returns 1 when there is one player' do
      game.add_player('player1')
      expected_game_size = 1
      expect(game.game_size).to eq expected_game_size
    end
    it 'returns 2 when there are two players' do
      game.add_player('P1')
      game.add_player('P2')
      expected_game_size = 2
      expect(game.game_size).to eq expected_game_size
    end
  end

  describe '#next_player_turn' do
    let(:game) { described_class.new([player1, player2]) }
    it 'sets current player turn to player2' do
      game.next_player_turn
      expect(game.current_player).to eq player2
    end
    it 'can loop back around to player1' do
      game.next_player_turn
      game.next_player_turn
      expect(game.current_player).to eq player1
    end
  end

  describe '#run_turn' do
    let(:card1) { Card.new('A') }
    context 'when a turn is run with 2 players' do
      context 'when player1 starts their turn with no cards' do
        let(:game) { described_class.new([player1, player2]) }
        let(:player1_data) { game.players.first }
        let(:player2_data) { game.players.last }
        before do
          player1_data.hand = []
          game.deck.cards = [card1]
        end
        it 'adds card to players hand, and its still their turn' do
          game.run_turn('player2', 'K')
          expected_hand_size = 1
          expect(player1_data.hand_size).to eq expected_hand_size
          expect(game.current_player.name).to eq player1_data.name
        end
      end

      context 'when player1 is asking player2 for a card they have' do
        let(:game) { described_class.new([player1, player2]) }
        let!(:player1_data) { game.players.first }
        let!(:player2_data) { game.players.last }
        before do
          player2_data.hand << card1
          player1_data.hand << card1
          game.run_turn('player2', 'A')
        end
        it 'player 1 gets the cards added to their hand' do
          expected_hand_size = 2
          expect(player1_data.hand_size).to eq expected_hand_size
        end
        it 'player2 gets the cards removed from their hand' do
          expect(player2_data.hand_size).to be_zero
        end
        context 'when player1 asks player2 for a card player2 does not have' do
          before do
            game.run_turn('player2', 'J')
            game.deck.cards.unshift Card.new('10')
          end
          context 'player1 does not take a card from player2' do
            it 'card is added to player1 hand from deck' do
              expected_hand_size = 3
              expect(player1_data.hand_size).to eq expected_hand_size
            end
            it 'current player is set to player2' do
              expect(game.current_player.name).to be player2_data.name
            end
          end
        end
        it 'returns a valid round result' do
          expect(game.results.last).to be_a TurnResult
        end
      end
      context 'when player1 asks for a card player2 does have and go fishing' do
        let(:game) { described_class.new([player1, player2]) }
        let!(:player1_data) { game.players.first }

        context 'when they pick up that card' do
          before do
            game.deck.cards.unshift(Card.new('A'))
            game.run_turn('player2', 'A')
          end

          it 'adds card to their hand' do
            expected_hand_size = 1
            expect(player1_data.hand_size).to eq expected_hand_size
          end

          it 'they are still current player' do
            expect(game.current_player.name).to eq player1_data.name
          end
        end
      end
      context 'when player1 asks a player that does not exist' do
        let(:game) { described_class.new([player1, player2]) }
        it 'returns nil' do
          expect(game.run_turn(3, 'J')).to be nil
        end
      end
      context 'when player1 is asking player2 for a card they do not have' do
        let(:game) { described_class.new([player1, player2]) }
        let!(:player1_data) { game.players.first }
        let!(:player2_data) { game.players.last }
        context 'when player1 does not pick up that card' do
          before do
            game.current_player_idx = 1
            player2_data.hand << Card.new('J')
            game.run_turn('player1', 'A')
          end
          it 'card is added to player1 hand' do
            expected_hand_size = 2
            expect(player2_data.hand_size).to eq expected_hand_size
          end
          it 'current player is set to next player in queue' do
            expect(game.current_player.name).to eq player1_data.name
          end
        end
      end
      context 'when there deck is empty and a player goes fishing' do
        let(:game) { described_class.new([player1, player2]) }
        let!(:player1_data) { game.players.first }
        let!(:player2_data) { game.players.last }
        before do
          game.deck.cards = []
          player1_data.hand << Card.new('J')
          game.run_turn('player1', 'A')
        end
        it 'does not give the player a card' do
          expected_hand_size = 1
          expect(player1_data.hand_size).to eq expected_hand_size
        end
        it 'sets the current player to next player in the queue' do
          expect(game.current_player.name).to eq player2_data.name
        end
      end
    end
  end
  describe '#winner?' do
    let!(:game) { described_class.new([player1, player2]) }
    context 'when there is no winner' do
      it 'returns' do
        expect(game.winner).to be_nil
      end
      context 'when the deck is empty and all player hands are empty' do
        let!(:game_player1) { game.players.first }
        let!(:game_player2) { game.players.last }
        before do
          game.deck = []
          game_player1.hand = []
          game_player1.books = [Book.new('K'), Book.new('2')]
          game_player2.hand = []
          game_player2.books = [Book.new('J')]
        end
        it 'returns the player with the most books' do
          expect(game.winner.name).to be game_player1.name
        end
        context 'when there is a tie for most books' do
          it 'returns the player with the highest book' do
            game_player1.books.pop
            expect(game.winner).to be game_player1
          end
        end
      end
    end
  end

  describe '#list_of_ranks' do
    context 'when a player has 3 cards' do
      let(:player_name) { 'Player1' }
      let(:game) { described_class.new([Player.new(player_name)]) }
      before do
        game.players.first.hand = [Card.new('J'), Card.new('J'), Card.new('10')]
      end

      it 'returns all of players ranks' do
        expected_size = 2
        expect(game.list_of_ranks(player_name).size).to eq expected_size
      end
    end
  end

  describe '#list_of_players' do
    context 'when there are two players' do
      let(:player_name) { 'Player2' }
      let(:game) { described_class.new([Player.new, Player.new(player_name)]) }
      it 'returns a list of players that is not the current player' do
        result = game.list_of_players(player_name)
        expected_size = 1
        expected_name = 'Player1'
        expect(result.size).to eq expected_size
        expect(result.first).to eq expected_name
      end
    end
  end
  describe '#latest_result' do
    let(:game) { described_class.new([user1, user2]) }
    before do
      game.results << TurnResult.new(
        current_player: nil, opponent: nil,
        card_asked_for: 'K', cards_taken: nil,
        card_picked_up: nil, goes_again: nil
      )
    end
  end

  describe '#as_json' do
    let(:game) { described_class.new([Player.new('Player1'), Player.new('Player1')]) }
    before do
      game.start
      game.results << TurnResult.new(
        current_player: Player.new('Player1'), opponent: Player.new('Player2'),
        card_asked_for: 'K', cards_taken: [],
        card_picked_up: nil, goes_again: false
      )
    end
    it 'returns json that matches schema' do
      expect(game.as_json('Player1')).to match_json_schema('game')
    end
  end

 # ^ Validation methods
  describe '#valid_rank?' do
    let(:game) { described_class.new([player1, player2]) }
    context 'when the rank provided is a not valid standard rank' do
      it 'returns false' do
        invalid_rank = 'L'
        expect(game.valid_rank?(invalid_rank)).to be false
      end
    end
    context 'when the rank provided is a valid standard rank' do
      it 'returns true' do
        valid_rank = 'K'
        expect(game.valid_rank?(valid_rank)).to be true
      end
    end
    context 'when the lower case rank provided is a valid standard rank' do
      it 'returns true' do
        valid_rank = 'k'
        expect(game.valid_rank?(valid_rank)).to be true
      end
    end
  end
  describe '#card?' do
    let(:game) { described_class.new([player1, player2]) }
    let(:rank_asked_for) { 'K' }
    context 'when the player does not have the card they asked for' do
      it 'returns false' do
        expect(game.card?(rank_asked_for)).to be false
      end
    end
    context 'when the player does have the card they asked for' do
      it 'returns true' do
        game.current_player.add_cards([Card.new('K')])
        expect(game.card?(rank_asked_for)).to be true
      end
    end
  end
  describe '#turn_skipped?' do
    let(:game) { described_class.new([player1, player2]) }
    let(:player) { game.current_player }
    context 'when the players hand and/or the deck is not empty' do
      it 'returns false' do
        game.start
        expect(game.turn_skipped?).to be false
      end
    end
    context 'when the players hand and deck is empty' do
      it 'returns true' do
        game.deck = []
        player.hand = []
        expect(game.turn_skipped?).to be true
      end
    end
  end

  describe 'started?' do
    let(:game) { described_class.new([player1, player2]) }
    it 'returns true when game has been started' do
      game.start
      expect(game.started?).to be true
    end

    it 'returns false when the game has not been started' do
      expect(game.started?).to be false
    end
  end
end
