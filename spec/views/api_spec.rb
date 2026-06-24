require_relative '../../server'
require_relative '../../lib/go_fish/card'

describe Server, type: :request do
  after(:each) do
    Server.reset!
  end

  include Rack::Test::Methods

  def app
    Server.new
  end

  it 'returns a response matching the join schema' do
    post '/join', { 'name' => 'Bot' }.to_json, { 'HTTP_ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
    expect(last_response).to be_ok
    expect(last_response).to match_json_schema('join')
  end

  describe 'GET /game' do
    it 'prevents unauthorized requests' do
      get '/game', {}, http_header('')
      expect(last_response.status).to eq 401
    end

    it 'allows authorized requests' do
      encoded = join_game
      get '/game', {}, http_header(encoded)
      expect(last_response).to be_ok
    end
    it 'returns a response matching the game schema' do
      encoded = join_game
      get '/game', {}, http_header(encoded)
      expect(last_response).to be_ok
      expect(last_response.body).to match_json_schema('game')
    end
  end

  describe 'POST /game' do
    let!(:encoded) { join_game }
    before do
      visit '/'
      fill_in :name, with: 'John'
      click_on 'Join'
    end
    it 'returns a response matching the game schema' do
      post '/game', { 'rank' => 'K', 'player' => 'John' }.to_json, http_header(encoded)
      expect(last_response).to be_ok
      expect(last_response.body).to match_json_schema('game')
      expect(JSON.parse(last_response.body)['round_results']).to_not be_empty
    end
  end

  def http_header(encoded)
    {
      'HTTP_ACCEPT' => 'application/json',
      'CONTENT_TYPE' => 'application/json',
      'HTTP_AUTHORIZATION' => "Basic #{encoded}"
    }
  end

  def join_game
    post '/join', { 'name' => 'Bot' }.to_json, { 'HTTP_ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
    api_key = JSON.parse(last_response.body)['api_key']
    Base64.encode64("#{api_key}:X").strip
  end
end
