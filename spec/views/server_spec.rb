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
        end
        player1_name = 'Player 1'
        player2_name = 'Player 2'
        expect(session1).to have_content(player2_name)
        expect(session2).to have_content(player1_name)
      end
    end

    context 'when multiple players join with the same name' do
      let!(:session1) { Capybara::Session.new(:rack_test, Server.new) }
      let!(:session2) { Capybara::Session.new(:rack_test, Server.new) }
      let(:sessions) { [session1, session2] }

      before do
        sessions.each do |session|
          session.visit '/'
          session.fill_in :name, with: 'John'
          session.click_on 'Join'
        end
      end
      it 'sends second player back to login with error message' do
        expected_path = '/game'
        expected_path1 = '/wrong-name'
        expected_content = 'That name is already taken'
        expect(session1).to have_current_path(expected_path)
        expect(session2).to have_current_path(expected_path1)
        expect(session2).to have_content(expected_content)
      end
    end

    context 'when a player sends a name with zero characters' do
      before do
        visit '/'
        fill_in :name, with: ''
        click_on 'Join'
      end
      it 'sends back to login with error message' do
        expected_path = '/wrong-name'
        expected_content = 'That name is already taken'
        expect(page).to have_current_path(expected_path)
        expect(page).to have_content(expected_content)
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
            expected_card_count = 14
            expected_accordion_count = 1
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
    context 'when a round is played' do
      it 'a card has been added to the current players hand' do
        session1.visit '/game'
        session1.click_on 'Ask'
        expected_count = 8
        expect(session1).to have_selector('.gf-game__hand .playing-card', count: expected_count, visible: :all)
      end

      it 'all players see a feed result' do
        session1.visit '/game'
        session1.click_on 'Ask'
        sessions.each do |session|
          session.visit '/game'
          expect(session).to have_selector('.game-feed__question')
          expect(session).to have_selector('.game-feed__results')
        end
      end
      # ^ add test to check hands to see if the cards have been traded?

    end

    context 'when a player wins' do
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
        expected_content = 'GAME OVER!'
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
