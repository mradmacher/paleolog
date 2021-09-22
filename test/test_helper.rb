# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'lib')
ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/rg'
require 'minitest/hooks/default'
require 'paleolog'

# FIXTURES_DIR = File.join(__dir__, 'fixtures')

class Minitest::HooksSpec
  def around
    Paleolog::Repo::Config.db.transaction(:rollback=>:always, :auto_savepoint=>true) { super }
  end
end
