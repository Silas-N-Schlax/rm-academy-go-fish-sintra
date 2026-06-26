require_relative '../../server'
require_relative '../../lib/go_fish/card'
require_relative '../../lib/go_fish/book'

describe Server, type: :system  do
  after(:each) do
    Server.reset!
  end

  include Rack::Test::Methods

  def app = Server.new

  describe '/join' do
    it 'player sees login if they do not have a api_key' do
      visit '/game'
      expected_path = '/'
      expect(page).to have_current_path(expected_path)
    end

    it 'is possible to join a lobby' do
      visit '/'
      fill_in :name, with: 'John'
      click_on 'Join'
      expect(page).to have_content('Players')
      expect(page).to have_current_path '/lobby'
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
        start_game(session1)
      end
      it 'each player is displayed on the respective screen' do
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
        expected_path = '/lobby'
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
  describe 'GET /lobby' do
    context 'when a player does not have a api_key' do
      it 'redirects to /' do
        visit '/lobby'
        expect(page).to have_current_path '/'
      end
    end

    context 'when there is only one player and someone goes to /game' do
      it 'redirects to /lobby' do
        join_game(page, 'John')
        visit '/game'
        expect(page).to have_current_path '/lobby'
      end
    end

    context 'when there are two players and the buttons is pressed' do
      let!(:session1) { Capybara::Session.new(:rack_test, Server.new) }
      let!(:session2) { Capybara::Session.new(:rack_test, Server.new) }
      let(:sessions) { [session1, session2] }
      before do
        sessions.each_with_index do |session, i|
          join_game(session, "Player#{i + 1}")
        end
        start_game(session1)
      end
      it 'redirects to /game' do
        sessions.each do |session|
          session.visit '/lobby'
          expect(session).to have_current_path '/game'
        end
      end
      it 'starts the game' do
        expect(Server.game.started?).to be true
      end
      it 'sends to /game if game is started' do
        sessions.each do |session|
          session.visit '/lobby'
          expect(session).to have_current_path '/game'
        end
      end
    end

    context 'when there are two or more players and the buttons is pressed' do
      it 'redirects to /game'
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
          start_game(session1)
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
          before do
            game = Server.game
            game.start
            game.players.each do |player|
              player.hand = [Card.new('J'), Card.new('J'), Card.new('10'), Card.new('10'), Card.new('3')]
            end
          end
          it 'populates players and rank selections' do
            sessions.each do |session|
              session.visit '/game'
              expected_player_count = 1
              expected_rank_count = 3
              expect(session).to have_selector('#player-option', count: expected_player_count, visible: false)
              expect(session).to have_selector('#rank-option', count: expected_rank_count, visible: false)
            end
          end
        end
      end
    end
  end

  describe 'POST /game' do
    let!(:session1) { Capybara::Session.new(:rack_test, Server.new) }
    let!(:session2) { Capybara::Session.new(:rack_test, Server.new) }
    let(:sessions) { [session1, session2] }

    before do
      sessions.each_with_index do |session, i|
        session.visit '/'
        session.fill_in :name, with: "Player #{i + 1}"
        session.click_on 'Join'
      end
      start_game(session1)
    end
    context 'when a round is played' do
      it 'a card has been added to the current players hand' do
        session1.visit '/game'
        session1.click_on 'Ask'
        expected_count = 8
        sleep 0.2
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
      it 'redirects winner to game_over page' do
        expected_path = '/game-over'
        expected_content = "#{game.winner.name} won the game!"
        expect(session1).to have_current_path(expected_path)
        expect(session1).to have_content(expected_content)
      end
    end
  end

  describe 'GET /game-over' do
    let!(:session1) { Capybara::Session.new(:rack_test, Server.new) }
    let!(:session2) { Capybara::Session.new(:rack_test, Server.new) }
    let(:sessions) { [session1, session2] }
    let(:game) { Server.game }

    before do
      sessions.each_with_index do |session, i|
        join_game(session, "Player #{i + 1}")
      end
      start_game(session1)
    end
    context 'when the game is not over' do
      it 'redirects to game' do
        sessions.each do |session|
          session.visit 'game-over'
          expect(session).to have_current_path '/game'
        end
      end
    end

    context 'when the game is over' do
      before do
        game.deck.cards = []
        game.players.each_with_index do |player, i|
          player.hand = []
          player.books = [Book.new((i + 4).to_s)]
        end
      end
      it 'resets game and api_keys and redirects to login page' do
        session1.visit '/game'
        expect(session1).to have_current_path '/game-over'
        expect(session1).to have_content(game.winner.name)
        session1.click_on 'Play Again'
        expect(session1).to have_current_path '/'
        expect(Server.game.started?).to be false
        expect(Server.api_keys).to be_empty
      end
    end
  end

  describe 'POST /reset' do
    context 'when someone tries to reset the game when its not over' do
      it 'redirects to /' do
        post '/reset', {}, { 'HTTP_ACCEPT' => 'application/html', 'CONTENT_TYPE' => 'application/html' }
        expect(page).to have_current_path '/'
      end
    end
  end

  def join_game(session, name)
    session.visit '/'
    session.fill_in :name, with: name
    session.click_on 'Join'
  end

  def start_game(session)
    session.visit '/lobby'
    session.click_on 'Start Game'
  end
end
