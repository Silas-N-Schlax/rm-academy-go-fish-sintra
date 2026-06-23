require_relative '../../server.rb'
require_relative '../../lib/go_fish/card'

describe Server do
  after(:each) do
    Server.reset!
  end

  describe '/join' do
    it 'player sees login if they do not have a api_key' do
      visit '/game'
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
            expected_card_count = 21
            expected_accordion_count = 2
            expect(session).to have_selector('.playing-card', count: expected_card_count, visible: false)
            expect(session).to have_selector('.accordion', count: expected_accordion_count)
          end
        end

        context 'when the form controls are populated' do
          it 'populates players and rank selections' do
            sessions.each do |session|
              session.visit '/game'
              expected_player_count = 1
              expected_rank_count = 7
              expect(session).to have_selector('#player-option', count: expected_player_count, visible: false)
              expect(session).to have_selector('#rank-option', count: expected_rank_count, visible: false)
            end
          end
        end
      end
    end
  end

  describe '/ask' do
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
    it 'plays a round' do
      session1.visit '/game'
      session1.click_on 'Ask'
      sessions.each do |session|
        session.visit '/game'
        expect(session).to have_selector('.game-feed__turn')
        expect(session).to have_selector('.game-feed__question')
        expect(session).to have_selector('.game-feed__results')
      end
    end

    context 'when a play tries to ask but its not their turn' do
      before do
        session2.visit '/game'
        session2.click_on 'Ask'
      end
      it 'displays alert message to player and rejects turn' do
        expected_message = 'Its not your turn'
        expect(session2).to have_content expected_message
      end

      it 'does not play turn' do
        sessions.each do |session|
          session.visit '/game'
          expected_hand_size = 7
          expect(session).to have_selector('.gf-game__hand .playing-card', count: expected_hand_size)
        end
      end
    end

    fcontext 'when a player wins' do
      let(:game) { Server.game }
      before do
        game.players = []
        game.add_player('Player 1')
        game.add_player('Player 2')
        game.deck.cards = []
        game.players.first.hand = [Card.new('J'), Card.new('J'), Card.new('J')]
        game.players.last.hand = [Card.new('J')]
        session1.visit '/game'
        session1.click_on 'Ask'
      end
      it 'redirects winner to winning page' do
        expected_path = '/game-over'
        expected_content = 'Game Over'
        expect(session1).to have_current_path(expected_path)
        expect(session1).to have_content(expected_content)
      end
      it 'revokes api_keys and restarts game' do
        expect(Server.game.started?).to be false
        expect(Server.api_keys).to be_empty
      end
    end
  end
end
