require 'sinatra'
require 'sinatra/json'
require 'json'

require_relative 'requests/data_game_session'

DEFAULT_LIVES = 5
DEFAULT_LENGTH = 10

post '/new-game' do
  json_new_game = JSON.parse(request.body.read)

  length = json_new_game['length'] || DEFAULT_LENGTH
  payload = {
    lives: json_new_game['lives'] || DEFAULT_LIVES,
    length: length
  }

  game_session = DataGameSession.create_game_session(payload)
  if response
    game_session.delete('answer')
    halt 201, json(game_session: game_session)
  else
    halt 500, json(message: 'internal server error')
  end
end

put '/guess' do
  json_request = JSON.parse(request.body.read)
  game_session_id = json_request['game_session_id']
  game_session = DataGameSession.get_game_session(game_session_id)
  
  halt 404, json(message: 'game not found') unless game_session

  already_answered = game_session['current_progress'] == (game_session['answer'])
  halt 403, json(message: 'already answered', game_session: game_session) if already_answered

  empty_lives = game_session['lives'] == 0
  halt 403, json(message: 'game over', game_session: game_session) if empty_lives

  answer = game_session['answer']
  game_session.delete('answer')

  guessed_letter = json_request['guessed_letter'].to_s.upcase

  letter_is_invalid = guessed_letter.size != 1
  halt 403, json(message: 'you can only try with exactly one letter', game_session: game_session) if letter_is_invalid  

  letter_already_tried = game_session['used_letters'].include?(guessed_letter)
  halt 403, json(message: 'you already tried this letter', game_session: game_session) if letter_already_tried
  
  letter_is_not_alphabet = !(guessed_letter =~ /[A-Z]/)
  halt 403, json(message: 'letter must be an alphabet', game_session: game_session) if letter_is_not_alphabet

  if answer.include?(guessed_letter)
    answer.each_char.with_index do |char, index|
      game_session['current_progress'][index] = guessed_letter if char == guessed_letter
    end

    game_session['used_letters'] += guessed_letter

    DataGameSession.update_game_session(game_session_id, game_session)

    if game_session['current_progress'] == (answer)
      game_session['answer'] = answer
      json message: 'congratulations!', game_session: game_session
    else
      json message: 'correct letter', game_session: game_session
    end
  else
    game_session['lives'] -= 1
    game_session['used_letters'] += guessed_letter

    DataGameSession.update_game_session(game_session_id, game_session)

    if game_session['lives'] == 0
      game_session['answer'] = answer
      json message: 'game over', game_session: game_session
    else
      json message: 'incorrect letter', game_session: game_session
    end
  end
end

get '/game-status' do
  game_status_code = {
    game_is_ongoing: 100,
    game_is_won: 101,
    game_is_lost: 102,
  }

  json_request = JSON.parse(request.body.read)
  game_session_id = json_request['game_session_id']
  game_session = DataGameSession.get_game_session(game_session_id)
  
  halt 404, json(message: 'game not found') unless game_session

  empty_lives = game_session['lives'] == 0
  halt 200, json(game_status: game_status_code[:game_is_lost], game_session: game_session) if empty_lives

  already_answered = game_session['current_progress'] == (game_session['answer'])
  halt 200, json(game_status: game_status_code[:game_is_won], game_session: game_session) if already_answered

  game_session.delete('answer')
  halt 200, json(game_status: game_status_code[:game_is_ongoing], game_session: game_session)
end
