# frozen_string_literal: true

require 'bcrypt'

module Paleolog
  class Authorizer
    class InvalidLogin < StandardError; end
    class InvalidPassword < StandardError; end

    ROLES = {
      Project => lambda do |user_id, id|
        Repo::Researcher.project_role(id, user_id)
      end,
      Paleolog::Counting => lambda do |user_id, id|
        Repo::Researcher.counting_role(id, user_id)
      end,
      Paleolog::Section => lambda do |user_id, id|
        Repo::Researcher.section_role(id, user_id)
      end,
      Paleolog::Sample => lambda do |user_id, id|
        Repo::Researcher.sample_role(id, user_id)
      end,
      Paleolog::Species => lambda do |user_id, _id|
        user_id ? Repo::Researcher::MANAGER : Repo::Researcher::NONE
      end,
    }.tap { |h| h.default = ->(_user_id, _id) { Repo::Researcher::NONE } }

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
      ROLES[entity_class].call(user_id, id) == Repo::Researcher::MANAGER
    end

    def can_view?(entity_class, id)
      ROLES[entity_class].call(user_id, id) != Repo::Researcher::NONE
    end
  end
end
