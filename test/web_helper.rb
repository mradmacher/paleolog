# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'web')

require 'rack/test'
require 'test_helper'
require 'app'

def app
  PaleologWeb
end

def login(user)
  #post '/login', { login: 'test', password: 'test123' }
  Paleolog::Authorizer.new(session).login('test', 'test123')
  env 'rack.session', session
end

def refute_guest_access(action)
  action.call
  assert_equal 401, last_response.status
end

def refute_user_access(action, user)
  session = {}
  Paleolog::Authorizer.new(session).login('test', 'test123')
  env('rack.session', session)

  action.call
  assert_equal 403, last_response.status
end

def assert_user_access(action, user)
  session = {}
  Paleolog::Authorizer.new(session).login('test', 'test123')
  env('rack.session', session)

  action.call
  assert_predicate last_response, :ok?
end
