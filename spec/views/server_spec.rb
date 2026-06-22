require_relative '../../server.rb'

describe Server do
  after(:each) do
    Server.reset!
  end

  context '/join' do
    it 'is possible to join a game' do
      visit '/'
      fill_in :name, with: 'John'
      click_on 'Join'
      expect(page).to have_content('Players')
      expect(page).to have_content('John'), 'Expected Player to be added to the game'
    end

    context 'when multiple players join' do
      let!(:session1) { Capybara::Session.new(:rack_test, Server.new) }
      let!(:session2) { Capybara::Session.new(:rack_test, Server.new) }
      let(:sessions) { [session1, session2] }

      before do
        sessions.each_with_index do |session, i|
          session.visit '/'
          session.fill_in :name, with: "John"
          session.click_on 'Join'
        end
      end

      it 'allows multiple players to join' do
        sessions.each_with_index do |session, i|
          expect(session).to have_content('Players')
        end
      end

      it 'each player has a unique api_key' do
        expected_keys_size = 2
        expect(Server.api_keys.length).to be expected_keys_size
      end
    end

    context 'when a player has already joined' do
      it 'redirects to game' do
        visit '/'
        fill_in :name, with: 'John'
        click_on 'Join'

        visit '/'
        expect(page).to have_content('Players')
      end
    end
  end
end

