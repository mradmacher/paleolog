# frozen_string_literal: true

require 'bcrypt'

module Paleolog
  class Authorizer
    class InvalidLogin < StandardError; end
    class InvalidPassword < StandardError; end

    NONE = :none
    MANAGER = :manager
    OBSERVER = :observer

    ROLES = {
      Project => lambda do |user_id, id|
        project_role(id, user_id)
      end,
      Paleolog::Counting => lambda do |user_id, id|
        counting_role(id, user_id)
      end,
      Paleolog::Section => lambda do |user_id, id|
        section_role(id, user_id)
      end,
      Paleolog::Sample => lambda do |user_id, id|
        sample_role(id, user_id)
      end,
      Paleolog::Species => lambda do |user_id, _id|
        user_id ? MANAGER : NONE
      end,
    }.tap { |h| h.default = ->(_user_id, _id) { NONE } }

    attr_reader :session

    def initialize(session)
      @session = session
    end

    def login(user)
      session[:user_id] = user.id
    end

    def authorize(login, password)
      result = Paleolog.db[:users].where(login: login).first
      raise InvalidLogin unless result

      user = Paleolog::User.new(**result)
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
      ROLES[entity_class].call(user_id, id) == MANAGER
    end

    def can_view?(entity_class, id)
      ROLES[entity_class].call(user_id, id) != NONE
    end

    def self.project_role(project_id, user_id)
      role_for(
        ds.where(project_id: project_id, user_id: user_id).select_map(:manager),
      )
    end

    def self.section_role(section_id, user_id)
      role_for(
        ds.where(user_id: user_id, Sequel[:sections][:id] => section_id)
          .join(:projects, Sequel[:projects][:id] => :project_id)
          .join(:sections, Sequel[:sections][:project_id] => :id).select_map(:manager),
      )
    end

    def self.sample_role(sample_id, user_id)
      role_for(
        ds.where(user_id: user_id, Sequel[:samples][:id] => sample_id)
          .join(:projects, Sequel[:projects][:id] => :project_id)
          .join(:sections, Sequel[:sections][:project_id] => :id)
          .join(:samples, Sequel[:samples][:section_id] => :id).select_map(:manager),
      )
    end

    def self.counting_role(counting_id, user_id)
      role_for(
        ds.where(user_id: user_id, Sequel[:countings][:id] => counting_id)
           .join(:projects, Sequel[:projects][:id] => :project_id)
           .join(:countings, Sequel[:countings][:project_id] => :id).select_map(:manager),
      )
    end

    def self.ds
      Paleolog.db[:research_participations]
    end

    def self.role_for(booleans)
      return NONE if booleans.empty?

      booleans.any? ? MANAGER : OBSERVER
    end
  end
end
