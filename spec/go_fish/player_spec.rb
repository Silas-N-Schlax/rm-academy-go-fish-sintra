require_relative '../../lib/go_fish/player'
require_relative '../../lib/go_fish/card'
require_relative '../../lib/go_fish/book'

describe Player do
  describe '#add_cards' do
    let(:player) { described_class.new('player1') }
    let(:card1) { Card.new('A', 'Spades') }
    let(:card2) { Card.new('K', 'Spades') }
    context 'when player has no cards' do
      it 'adds cards to bottom in correct orders' do
        example_hand = [card1, card2]
        player.add_cards(example_hand)
        expect(player.hand).to eq example_hand
        expect(player.hand_size).to eq 2
      end
    end

    context 'when player has cards' do
      let(:card3) { Card.new('2', 'Spades') }
      before do
        player.hand = [card3]
      end
      it 'adds cards in correct order and does not create deck' do
        example_hand = [card3, card1, card2]
        player.add_cards([card1, card2])
        expect(player.hand).to eq example_hand
        expect(player.hand_size).to eq example_hand.size
        expect(player.books_size).to be_zero
      end
    end

    context 'when a 4th card of the same rank is added' do
      before do
        player.hand = [card1, card1, card1, card2]
      end
      it 'creates a book with that rank' do
        expected_books_size = 1
        expected_hand_size = 1
        expect(player.add_cards([card1])).to be_a Book
        expect(player.books_size).to eq expected_books_size
        expect(player.hand_size).to eq expected_hand_size
      end
    end
  end

  describe '#hand_size' do
    let(:player) { described_class.new('player1') }
    it 'returns the current hand size' do
      expect(player.hand_size).to eq 0
    end

    it 'returns current hand size of hand with 1 card' do
      player.add_cards([Card.new('A', 'Spades')])
      expect(player.hand_size).to eq 1
    end

    it 'returns current hand size of hand with 2 cards' do
      player.add_cards([Card.new('A', 'Spades'), Card.new('10', 'Spades')])
      expect(player.hand_size).to eq 2
    end
  end

  describe '#take_cards_of_rank' do
    let(:player) { described_class.new('player') }
    context 'when player does not have the correct card' do
      it 'returns nil' do
        expect(player.take_cards_of_rank('A')).to be_empty
      end
    end

    context 'when player has one of the correct card' do
      let(:card) { Card.new('A') }
      before do
        player.hand = [card, Card.new('K'), Card.new('J')]
      end

      it 'returns array of card and remove card from hand' do
        expect(player.take_cards_of_rank('A')).to eq [card]
        expect(player.hand_size).to eq 2
      end
    end

    context 'when player has two of the correct card' do
      let(:card1) { Card.new('K') }
      let(:card2) { Card.new('K') }
      before do
        player.hand = [card1, Card.new('A'), card2]
      end
      it 'returns array of cards and remove cards from hand' do
        expect(player.take_cards_of_rank('K')).to eq [card1, card2]
        expect(player.hand_size).to eq 1
      end
    end
  end

  describe '#books_size' do
    let(:player) { described_class.new('player1') }
    it 'returns the current hand size' do
      expect(player.books_size).to eq 0
    end
    it 'returns current hand size of hand with 1 card' do
      player.books = ([Book.new('A')])
      expect(player.books_size).to eq 1
    end
    it 'returns current hand size of hand with 2 cards' do
      player.books = ([Book.new('A'), Book.new('K')])
      expect(player.books_size).to eq 2
    end
  end

  describe '#cards?' do
    let(:player) { described_class.new('player1') }
    it 'returns false if no cards found' do
      card_rank = 'J'
      expect(player.card?(card_rank)).to be false
    end

    it 'returns true if 1 card found' do
      player.add_cards([Card.new('J')])
      card_rank = 'J'
      expect(player.card?(card_rank)).to be true
    end

    it 'returns true if 2 cards found' do
      player.add_cards([Card.new('J'), Card.new('J')])
      card_rank = 'J'
      expect(player.card?(card_rank)).to be true
    end
  end

  describe '#empty_hand?' do
    let(:player) { described_class.new('player1') }
    it 'returns false if hand is full' do
      player.add_cards([Card.new('J')])
      expect(player.empty_hand?).to be false
    end

    it 'returns true if hand is empty' do
      expect(player.empty_hand?).to be true
    end
  end

  describe '#ranks' do
    let(:player) { described_class.new }
    let(:card) { Card.new('J') }
    let(:card1) { Card.new('10') }
    let(:card2) { Card.new('3') }
    before do
      player.hand = [card, card, card1, card1, card2]
    end
    it 'returns all ranks in array' do
      result = player.ranks
      expected_size = 3
      expected_sorted_array = %w[3 10 J]
      expect(result.size).to eq expected_size
      expect(result).to eq expected_sorted_array
      result.each { |rank| expect(rank).to be_a String }
    end
  end

  describe '#sort_hand' do
    let(:player) { described_class.new }
    let(:card) { Card.new('10') }
    let(:card1) { Card.new('2') }
    let(:card2) { Card.new('3') }
    before do
      player.hand = [card, card1, card2]
    end
    it 'returns sorted array by rank' do
      sorted_array = [card1, card2, card]
      expect(player.sort_hand).to eq sorted_array
    end
  end
end
