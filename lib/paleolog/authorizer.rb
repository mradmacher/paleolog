# frozen_string_literal: true

require 'bcrypt'

module Paleolog
  class Authorizer
    class InvalidLogin < StandardError; end
    class InvalidPassword < StandardError; end

    MANAGE_PRIVILEGES = {
      Paleolog::Project => lambda do |user_id, id|
        Paleolog::Repo::Researcher.can_manage_project?(user_id, id)
      end,
      Paleolog::Counting => lambda do |user_id, id|
        Paleolog::Repo::Researcher.can_manage_counting?(user_id, id)
      end,
      Paleolog::Section => lambda do |user_id, id|
        Paleolog::Repo::Researcher.can_manage_section?(user_id, id)
      end,
    }.tap { |h| h.default = ->(_user_id, _id) { false } }

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
    alias authenticated? logged_in?

    def logout
      session.clear
    end

    def can_manage?(entity_class, id)
      MANAGE_PRIVILEGES[entity_class].call(user_id, id)
    end

    def can_view?(_entity_class, _id)
      false
    end
  end
end
