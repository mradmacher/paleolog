# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'lib')
ENV['RACK_ENV'] = 'test'
ENV['PALEOLOG_DB_URI'] = 'postgres://paleolog:paleolog@localhost:5433/paleolog'

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/rg'
# require 'minitest/hooks/default'
require 'paleolog'

class HappyAuthorizer
  def authenticated? = true
  def can_manage?(_, _) = true
end

# class Minitest::DbCleanup
#  def around
#    Paleolog::Repo::Config.db.transaction(rollback: :always, auto_savepoint: true) { super }
#  end
#
#  def around_all
#    Paleolog::Repo::Config.db.transaction(rollback: :always) { super }
#  end
# end
# class Minitest::Spec
#  def run(*args, &block)
#    Paleolog::Repo::Config.db.transaction(:rollback=>:always, :auto_savepoint=>false){super}
#  end
# end
