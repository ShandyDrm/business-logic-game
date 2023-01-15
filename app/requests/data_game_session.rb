require 'faraday'

class DataGameSession
  def self.conn
    @@conn ||= Faraday.new(url: ENV['DATA_GAME_SESSION_URL'], headers: {'Content-Type' => 'application/json'}) do |config|
      config.request :json
      config.response :json
      config.adapter Faraday.default_adapter
    end
  end

  def self.get_game_session(game_session_id)
    response = conn.get("game-sessions/#{game_session_id}")
    p response.status, response.body
    return nil unless response.status == 200

    response.body
  end

  def self.create_game_session(payload)
    conn.post('game-sessions', payload).body
  end

  def self.update_game_session(game_session_id, payload)
    conn.patch("game-sessions/#{game_session_id}", payload).body
  end
end
