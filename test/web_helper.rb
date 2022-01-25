# frozen_string_literal: true
$LOAD_PATH << File.join(__dir__, '..', 'web')

require 'rack/test'
require 'test_helper'
require 'app'

def app
  PaleologWeb
end
