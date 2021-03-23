# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'lib')
ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/rg'
require 'paleolog'

# FIXTURES_DIR = File.join(__dir__, 'fixtures')
