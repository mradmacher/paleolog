# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'web')

require 'rack/test'
require 'test_helper'
require 'app'

def app
  PaleologWeb
end

def login(user)
  Paleolog::Authorizer.new(session).login(user)
  env 'rack.session', session
end

def assert_unauthorized(action)
  action.call
  assert_equal 401, last_response.status
end

def assert_forbidden(action)
  action.call
  assert_equal 403, last_response.status
end

def assert_permitted(action)
  action.call
  assert_predicate last_response, :ok?
end
