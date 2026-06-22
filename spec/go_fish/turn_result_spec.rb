require_relative '../../lib/go_fish/turn_result'
require_relative '../../lib/go_fish/card'
require_relative '../../lib/go_fish/player'

describe TurnResult do
  let(:results) do
    described_class.new(
      current_player: Player.new('Player1'),
      opponent: Player.new('Player2'),
      cards_taken: [Card.new('K', 'Hearts')],
      card_asked_for: 'K',
      card_picked_up: Card.new('J'),
      goes_again: false
    )
  end

  describe '#for_current' do
    it 'returns the message for the current players if they got cards' do
      expected_message = 'You asked for a K, took the following from Player2:\n- King of Hearts'
      expect(results.for_current.join('\n')).to eq expected_message
    end
    it 'returns the message for the current player if they did not get cards' do
      expected_message = 'You asked for a K, Player2 did not have any K\'s.'
      results.cards_taken = []
      expect(results.for_current.join('\n')).to eq expected_message
    end
  end
  describe '#for_all' do
    it 'returns message for the all if current player got cards' do
      expected_message = 'Player1 asked for a K and took the following cards from Player2:\n- King of Hearts'
      expect(results.for_all.join('\n')).to eq expected_message
    end
    it 'returns message for all if the current player did not get cards' do
      expected_message = 'Player1 asked for a K, Player2 did not have any K\'s.'
      results.cards_taken = []
      expect(results.for_all.join('\n')).to eq expected_message
    end
  end
  describe '#go_fish' do
    it 'returns go fish message that reveals cards' do
      expected_message = 'You went fishing and picked up a Jack of Spades. You do not get to go again.'
      expect(results.go_fish).to eq expected_message
    end
  end
  describe '#went_fishing' do
    it 'returns go fish message that does not reveals cards' do
      expected_message = 'Player1 went fishing, they do not get to go again.'
      expect(results.went_fishing).to eq expected_message
    end
  end
end
