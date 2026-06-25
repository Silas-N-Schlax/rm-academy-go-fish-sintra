require_relative '../../lib/go_fish/turn_result'
require_relative '../../lib/go_fish/card'
require_relative '../../lib/go_fish/player'
require_relative '../../lib/go_fish/book'

describe TurnResult do
  let(:results) do
    described_class.new(
      current_player: Player.new('Player1'),
      opponent: Player.new('Player2'),
      cards_taken: [],
      card_asked_for: 'K',
      card_picked_up: Card.new('J'),
      goes_again: false,
      created_book: Book.new('J')
    )
  end
  let(:current) { 'Player1' }
  let(:opponent) { 'Player2' }

  describe '#question' do
    it 'returns the question that was asked' do
      expected_message = 'Player1 asked Player2 for any Ks'
      expect(results.question.join).to eq expected_message
    end
  end

  describe '#answer' do
    it 'returns the answer when the player does not have the card' do
      expected_message = 'Go Fish: Player2 didn\'t have any Ks'
      expect(results.answer).to eq expected_message
    end

    it 'returns the answer when the player does have the card' do
      expected_message = 'Player2 had 1 Ks'
      results.cards_taken = [Card.new('K')]
      expect(results.answer).to eq expected_message
    end
  end

  describe '#go_fish' do
    context 'when its the current player' do
      context 'returns message telling player what they picked up' do
        it 'player gets what they wanted' do
          expected_message = 'You drew a J of Spades and do not get to go again'
          expect(results.go_fish(current)).to eq expected_message
        end
        it 'player does not get what they wanted' do
          results.goes_again = true
          expected_message = 'You drew a J of Spades and get to go again'
          expect(results.go_fish(current)).to eq expected_message
        end
      end
    end

    context 'when its the opponent' do
      it 'returns message when player gets what they wanted' do
        results.goes_again = true
        expected_message = 'Player1 drew a card and gets to go again'
        expect(results.go_fish(opponent)).to eq expected_message
      end

      it 'returns message when player did not get what they wanted' do
        expected_message = 'Player1 drew a card and does not get to go again'
        expect(results.go_fish(opponent)).to eq expected_message
      end

      it 'returns nil when player did not go fishing' do
        results.card_picked_up = nil
        expect(results.go_fish(opponent)).to be_nil
      end
    end
  end

  describe '#book_created' do
    it 'returns message for current player that a book has been created' do
      expected_message = 'You created a book of Js'
      expect(results.book_created(current)).to eq expected_message
    end

    it 'returns message for all players that a book has been created' do
      expected_message = 'Player1 created a book of Js'
      expect(results.book_created(opponent)).to eq expected_message
    end

    it 'returns nil when a player did not create a book with the book' do
      results.created_book = nil
      expect(results.book_created(current)).to be_nil
    end
  end

  describe '#as_json' do
    let(:mock_hash) do
      {
        current_player: current,
        rank: 'K',
        went_fishing: true,
        display: 'Go Fish: Player2 didn\'t have any Ks. You drew a J of Spades and do not get to go again'
      }
    end
    it 'returns hash that matches json schema' do
      expect(results.as_json(current)).to eq mock_hash
      expect(results.as_json(current).to_json).to match_json_schema('round_result')
    end
  end

  describe '#add_got_card_record' do
    let(:player) { Player.new }
    let(:card) { Card.new('J') }
    before { results.add_got_card_record(player, card) }
    it 'adds record to array' do
      expected_size = 1
      got_card = results.got_card.first
      expect(results.got_card.size).to eq expected_size
      expect(got_card.first).to eq player
      expect(got_card.last).to eq card
    end
  end

  describe '#got_card_message' do
    let(:player1) { Player.new('Player1') }
    let(:player2) { Player.new('Player2') }
    let(:card1) { Card.new('K') }
    let(:card2) { Card.new('J') }
    let(:expected_message1) { 'You ran out of cards, you drew a K' }
    let(:expected_message2) { 'Player1 ran out of cards, they drew a card' }
    before { results.add_got_card_record(player1, card1) }
    context 'when one player gets a card' do
      it 'returns an array with one message' do
        result = results.got_card_message(player1.name)
        expected_size = 1
        expect(result.size).to eq expected_size
        expect(result.first).to eq expected_message1
      end
    end
    context 'when two players get a card' do
      before { results.add_got_card_record(player2, card2) }
      it 'returns an array with two messages' do
        result1 = results.got_card_message(player1.name)
        result2 = results.got_card_message(player2.name)
        expected_size = 2
        expect(result1.size).to eq expected_size
        expect(result1.first).to eq expected_message1
        expect(result2.first).to eq expected_message2
      end
    end
  end
end
