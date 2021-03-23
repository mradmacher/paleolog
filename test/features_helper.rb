# frozen_string_literal: true

require 'test_helper'

require 'capybara/minitest'
require 'capybara/minitest/spec'
require './web'

Capybara.app = PaleologWeb

module Minitest
  class Test
    include Capybara::DSL
    include Capybara::Minitest::Assertions

    def after_teardown
      Capybara.reset_sessions!
      Capybara.use_default_driver
      super
    end
  end
end
