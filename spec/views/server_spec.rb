require_relative '../../server.rb'

describe Server do
  after(:each) do
    Server.reset!
  end

  describe '/join' do
    it 'player sees login if they do not have a session' do
      visit '/'
      expected_path = '/'
      expect(page).to have_current_path(expected_path)
    end
    
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
          session.fill_in :name, with: "Player #{i + 1}"
          session.click_on 'Join'
        end
      end
      it 'each player is displayed on the screen' do
        sessions.each do |session|
          session.visit '/game'
          expect(session).to have_content 'Player 1'
          expect(session).to have_content 'Player 2'
        end
      end
    end

    context 'when multiple players join with the same name' do
      let!(:session1) { Capybara::Session.new(:rack_test, Server.new) }
      let!(:session2) { Capybara::Session.new(:rack_test, Server.new) }
      let(:sessions) { [session1, session2] }

      before do
        sessions.each do |session|
          session.visit '/'
          session.fill_in :name, with: "John"
          session.click_on 'Join'
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

  describe '/game' do
    context 'when the player does not have a session' do
      it 'redirects to login page' do
        visit '/game'
        expected_path = '/'
        expect(current_path).to eq expected_path
      end
    end

    context 'when the player does have a session' do
      context 'when there are two players' do
        let!(:session1) { Capybara::Session.new(:rack_test, Server.new) }
        let!(:session2) { Capybara::Session.new(:rack_test, Server.new) }
        let(:sessions) { [session1, session2] }
        before do
          sessions.each_with_index do |session, i|
            session.visit '/'
            session.fill_in :name, with: "Player #{i + 1}"
            session.click_on 'Join'
          end
        end
        it 'starts the game' do
          Server.game.players.each do |player|
            expect(player.hand).to_not be_empty
          end
        end

        it 'loads the content on the page for the correct player' do
          sessions.each do |session|
            session.visit '/game'
            expect(session).to have_selector('.playing-card', count: 21, visible: false)
            expect(session).to have_selector('.accordion', count: 2)
          end
        end
      end
    end
  end
end

