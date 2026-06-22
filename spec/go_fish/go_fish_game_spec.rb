require_relative '../../lib/go_fish/card'
require_relative '../../lib/go_fish/user'
require_relative '../../lib/go_fish/go_fish_game'
require_relative '../../lib/go_fish/book'

describe GoFishGame do
  let(:user1) { User.new('client', 1) }
  let(:user2) { User.new('client', 2) }
  describe '#start' do
    context 'when a game is started with two players' do
      let(:game) { described_class.new([user1, user2]) }
      let(:game_user1) { game.users.first }
      let(:game_user2) { game.users.last }
      before { game.start }
      it 'deals 7 cards to each player' do
        expected_hand_size = 7
        game.users.each do |user|
          expect(user.player.hand_size).to eq expected_hand_size
        end
      end
      it 'cards are not in order' do
        default_hand1 = [Card.new('2'), Card.new('4'), Card.new('6'), Card.new('8'), Card.new('10')]
        default_hand2 = [Card.new('3'), Card.new('5'), Card.new('7'), Card.new('9'), Card.new('J')]
        expect(game_user1.player.hand).to_not eq default_hand1
        expect(game_user2.player.hand).to_not eq default_hand2
        expect(game_user1.player.hand).to_not be_empty
        expect(game_user2.player.hand).to_not be_empty
      end
    end
    context 'when a game is started with 4 players' do
      let(:user3) { User.new('client', 3) }
      let(:user4) { User.new('client', 4) }
      let(:game) { described_class.new([user1, user2, user3, user4]) }
      before { game.start }
      it 'deals 5 cards to each player' do
        expected_hand_size = 5
        game.users.each do |user|
          expect(user.player.hand_size).to eq expected_hand_size
        end
      end
    end
  end
  describe '#current_user' do
    let(:game) { described_class.new([user1, user2]) }
    it 'returns the current player' do
      expect(game.current_user).to eq user1
    end
  end

  describe '#find_player' do
    let(:game) { described_class.new([user1, user2]) }
    context 'when provided with id for user1' do
      it 'returns user1' do
        user1_id = 1
        result = game.find_user(user1_id)
        expect(result.name).to eq user1.name
      end
    end

    context 'when provided with an id for a non-existent player' do
      it 'returns nil' do
        user3_id = 3
        result = game.find_user(user3_id)
        expect(result).to be_nil
      end
    end
  end

  describe '#next_user_turn' do
    let(:game) { described_class.new([user1, user2]) }
    it 'sets current user turn to user2' do
      game.next_user_turn
      expect(game.current_user).to eq user2
    end
    it 'can loop back around to user1' do
      game.next_user_turn
      game.next_user_turn
      expect(game.current_user).to eq user1
    end
  end

  describe '#latest_result' do
    let(:game) { described_class.new([user1, user2]) }
    before do
      game.turn_results << TurnResult.new(
        current_user: nil, opponent: nil,
        card_asked_for: nil, cards_taken: nil,
        card_picked_up: nil, goes_again: nil
      )
    end
  end

  describe '#run_turn' do
    let(:card1) { Card.new('A') }
    context 'when a turn is run with 2 players' do
      context 'when user1 is asking user2 for a card they have' do
        let(:game) { described_class.new([user1, user2]) }
        let!(:user1_data) { game.users.first }
        let!(:user2_data) { game.users.last }
        before do
          user2_data.player.hand << card1
          game.run_turn(2, 'A')
        end
        it 'player 1 gets the cards added to their hand' do
          expected_hand_size = 1
          expect(user1_data.player.hand_size).to eq expected_hand_size
        end
        it 'user2 gets the cards removed from their hand' do
          expect(user2_data.player.hand_size).to be_zero
        end
        context 'when user1 asks user2 for a card user2 does not have' do
          before do
            game.run_turn(2, 'J')
            game.deck.cards.unshift Card.new('10')
            # ^ Work?
          end
          context 'user1 does not take a card from user2' do
            it 'card is added to user1 hand from deck' do
              expected_hand_size = 2
              expect(user1_data.player.hand_size).to eq expected_hand_size
            end
            it 'current player is set to user2' do
              expect(game.current_user.name).to be user2_data.name
            end
          end
        end
        it 'returns a valid round result' do
          expect(game.latest_result).to be_a TurnResult
        end
      end
      context 'when user1 asks for a card user2 does have and go fishing' do
        let(:game) { described_class.new([user1, user2]) }
        let!(:user1_data) { game.users.first }

        context 'when they pick up that card' do
          before do
            game.deck.cards.unshift(Card.new('A'))
            game.run_turn(2, 'A')
          end

          it 'adds card to their hand' do
            expected_hand_size = 1
            expect(user1_data.player.hand_size).to eq expected_hand_size
          end

          it 'they are still current player' do
            expect(game.current_user.name).to eq user1_data.name
          end
        end
      end
      context 'when user1 asks a player that does not exist' do
        let(:game) { described_class.new([user1, user2]) }
        it 'returns nil' do
          expect(game.run_turn(3, 'J')).to be nil
        end
      end
      context 'when user1 is asking user2 for a card they do not have' do
        let(:game) { described_class.new([user1, user2]) }
        let!(:user1_data) { game.users.first }
        let!(:user2_data) { game.users.last }
        context 'when user1 does not pick up that card' do
          before do
            game.current_user_idx = 1
            game.run_turn(1, 'A')
          end
          it 'card is added to user1 hand' do
            expected_hand_size = 1
            expect(user2_data.player.hand_size).to eq expected_hand_size
          end
          it 'current player is set to next player in queue' do
            expect(game.current_user.name).to eq user1_data.name
          end
        end
      end
      context 'when there deck is empty and a player goes fishing' do
        let(:game) { described_class.new([user1, user2]) }
        let!(:user2_data) { game.users.last }
        before do
          game.deck.cards = []
          game.run_turn(1, 'A')
        end
        it 'does not give the player a card' do
          expect(user2_data.player.hand_size).to be_zero
        end
        it 'sets the current player to next player in the queue' do
          expect(game.current_user.name).to eq user2_data.name
        end
      end
    end
  end
  describe '#winner?' do
    let!(:game) { described_class.new([user1, user2]) }
    context 'when there is no winner' do
      it 'returns' do
        expect(game.winner).to be_nil
      end
      context 'when the deck is empty and all user hands are empty' do
        let!(:game_user1) { game.users.first }
        let!(:game_user2) { game.users.last }
        before do
          game.deck = []
          game_user1.player.hand = []
          game_user1.player.books = [Book.new('K'), Book.new('2')]
          game_user2.player.hand = []
          game_user2.player.books = [Book.new('J')]
        end
        it 'returns the player with the most books' do
          expect(game.winner.id).to be game_user1.id
        end
        context 'when there is a tie for most books' do
          it 'returns the player with the highest book' do
            game_user1.player.books.pop
            expect(game.winner).to be game_user1
          end
        end
      end
    end
  end

 # ^ Validation methods
  describe '#valid_rank?' do
    let(:game) { described_class.new([user1, user2]) }
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
    let(:game) { described_class.new([user1, user2]) }
    let(:rank_asked_for) { 'K' }
    context 'when the player does not have the card they asked for' do
      it 'returns false' do
        expect(game.card?(rank_asked_for)).to be false
      end
    end
    context 'when the player does have the card they asked for' do
      it 'returns true' do
        game.current_user.player.add_cards([Card.new('K')])
        expect(game.card?(rank_asked_for)).to be true
      end
    end
  end
  describe '#turn_skipped?' do
    let(:game) { described_class.new([user1, user2]) }
    let(:user) { game.current_user }
    context 'when the players hand and/or the deck is not empty' do
      it 'returns false' do
        game.start
        expect(game.turn_skipped?).to be false
      end
    end
    context 'when the players hand and deck is empty' do
      it 'returns true' do
        game.deck = []
        user.player.hand = []
        expect(game.turn_skipped?).to be true
      end
    end
  end
end
