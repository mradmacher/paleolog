# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'lib')
ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/rg'
# require 'minitest/hooks/default'
require 'paleolog'

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
