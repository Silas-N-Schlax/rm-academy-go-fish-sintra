require_relative '../../lib/go_fish/book'

describe Book do
  describe '#to_s' do
    let(:book) { described_class.new('K') }
    it 'returns formatted string' do
      expected_string = 'Book of King'
      expect(book.to_s).to eq expected_string
    end
  end
end
