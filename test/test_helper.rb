# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'lib')
ENV['RACK_ENV'] = 'test'
ENV['PALEOLOG_DB_URI'] = 'postgres://paleolog:paleolog@localhost:5433/paleolog'

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/rg'
require 'paleolog'

class HappyAuthorizer
  attr_reader :user_id

  def initialize(user)
    @user_id = user.id
  end

  def authenticated? = true
  def can_manage?(_, _) = true
  def can_view?(_, _) = true
end

def happy_operation_for(operation_class, user)
  operation_class.new(Paleolog::Repo, HappyAuthorizer.new(user))
end
