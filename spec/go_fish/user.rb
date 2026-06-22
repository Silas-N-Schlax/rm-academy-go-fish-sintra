require_relative '../../lib/go_fish/user'

describe User do
  describe '#to_s' do
    let(:user) { described_class.new('client', 1) }
    before { user.name = 'Silas' }
    it 'sends player as a string' do
      expected_formatted_string = 'Silas - (1)'
      expect(user.to_s).to eq expected_formatted_string
    end
  end
end
