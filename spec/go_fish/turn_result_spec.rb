require_relative '../../lib/go_fish/turn_result'
require_relative '../../lib/go_fish/card'
require_relative '../../lib/go_fish/player'

describe TurnResult do
  let(:results) do
    described_class.new(
      current_player: Player.new('Player1'),
      opponent: Player.new('Player2'),
      cards_taken: [],
      card_asked_for: 'K',
      card_picked_up: Card.new('J'),
      goes_again: false
    )
  end

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
    let(:current) { 'Player1' }
    let(:opponent) { 'Player2' }
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

  # describe '#go_fish_current' do
  #   context 'returns message telling player what they picked up' do
  #     it 'player gets what they wanted' do
  #       expected_message = 'You drew a J of Spades and do not get to go again'
  #       expect(results.go_fish_current).to eq expected_message
  #     end
  #     it 'player does not get what they wanted' do
  #       results.goes_again = true
  #       expected_message = 'You drew a J of Spades and get to go again'
  #       expect(results.go_fish_current).to eq expected_message
  #     end
  #   end

  #   it 'returns nil when player did not go fishing' do
  #     results.card_picked_up = nil
  #     expect(results.go_fish_current).to be_nil
  #   end
  # end

  # describe '#go_fish_all' do
  #   it 'returns message when player gets what they wanted' do
  #     results.goes_again = true
  #     expected_message = 'Player1 drew a card and gets to go again'
  #     expect(results.go_fish_all).to eq expected_message
  #   end

  #   it 'returns message when player did not get what they wanted' do
  #     expected_message = 'Player1 drew a card and does not get to go again'
  #     expect(results.go_fish_all).to eq expected_message
  #   end

  #   it 'returns nil when player did not go fishing' do
  #     results.card_picked_up = nil
  #     expect(results.go_fish_all).to be_nil
  #   end
  # end

  # describe '#for_current' do
  #   it 'returns the message for the current players if they got cards' do
  #     expected_message = 'Pla asked for a K, took the following from Player2:\n- King of Hearts'
  #     expect(results.for_current.join('\n')).to eq expected_message
  #   end
  #   it 'returns the message for the current player if they did not get cards' do
  #     expected_message = 'You asked for a K, Player2 did not have any K\'s.'
  #     results.cards_taken = []
  #     expect(results.for_current.join('\n')).to eq expected_message
  #   end
  # end
  # describe '#for_all' do
  #   it 'returns message for the all if current player got cards' do
  #     expected_message = 'Player1 asked for a K and took the following cards from Player2:\n- King of Hearts'
  #     expect(results.for_all.join('\n')).to eq expected_message
  #   end
  #   it 'returns message for all if the current player did not get cards' do
  #     expected_message = 'Player1 asked for a K, Player2 did not have any K\'s.'
  #     results.cards_taken = []
  #     expect(results.for_all.join('\n')).to eq expected_message
  #   end
  # end
  # describe '#go_fish' do
  #   it 'returns go fish message that reveals cards' do
  #     expected_message = 'You went fishing and picked up a Jack of Spades. You do not get to go again.'
  #     expect(results.go_fish).to eq expected_message
  #   end
  # end
  # describe '#went_fishing' do
  #   it 'returns go fish message that does not reveals cards' do
  #     expected_message = 'Player1 went fishing, they do not get to go again.'
  #     expect(results.went_fishing).to eq expected_message
  #   end
  # end
end
