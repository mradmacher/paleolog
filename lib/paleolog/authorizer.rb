# frozen_string_literal: true

require 'bcrypt'

module Paleolog
  class Authorizer
    class InvalidLogin < StandardError; end

    class InvalidPassword < StandardError; end

    attr_reader :session

    def initialize(session)
      @session = session
    end

    def login(user)
      session[:user_id] = user.id
    end

    def authorize(login, password)
      user = Paleolog::Repo::User.find_by_login(login)
      raise InvalidLogin unless user
      raise InvalidPassword unless BCrypt::Password.new(user.password) == "#{user.password_salt}#{password}"

      login(user)
      user
    end

    def user_id
      session[:user_id]
    end

    def logged_in?
      session[:user_id]
    end

    def logout
      session.clear
    end
  end
end
