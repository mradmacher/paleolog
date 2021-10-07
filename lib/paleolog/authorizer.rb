# frozen_string_literal: true

require 'bcrypt'

module Paleolog
  class Authorizer
    class InvalidLogin < StandardError end
    class InvalidPassword < StandardError end
    def initialize(session)
      @session = session
    end

    def login(login, password)
      user = Paleolog::Repo::User.new.find_by_login(login)
      raise InvalidLogin unless user
      raise InvalidPassword unless BCrypt::Password.new(user.password) == "#{user.password_salt}#{password}"

      session[:user_id] = user.id
      user
    end

    def logged_in?
      session[:user_id]
    end

    def logout
      session.clear
    end
  end
end
