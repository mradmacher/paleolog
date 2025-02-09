# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'lib')
ENV['RACK_ENV'] = 'test'
ENV['PALEOLOG_DB_URI'] = 'sqlite://data/db/test.db'
ENV['PALEOLOG_DB_MAX_CONNECTIONS'] = '1' # for transactional feature tests

require 'minitest/autorun'
require 'minitest/hooks/default'
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
  operation_class.new(Paleolog.db, HappyAuthorizer.new(user))
end

# rubocop:disable Style/ClassAndModuleChildren
class Minitest::HooksSpec
  def around
    Paleolog::Config.db.transaction(rollback: :always, auto_savepoint: true) { super }
  end
end
# rubocop:enable Style/ClassAndModuleChildren
