# frozen_string_literal: true

require 'test_helper'

require 'capybara/minitest'
require 'capybara/minitest/spec'
require './web/app'

Capybara.app = PaleologWeb

module Minitest
  class Test
    include Capybara::DSL
    include Capybara::Minitest::Assertions

    def use_javascript_driver
      Capybara.current_driver = :selenium_headless
    end

    def after_teardown
      Capybara.reset_sessions!
      Capybara.use_default_driver
      super
    end
  end
end

Paleolog::Config.db.extension :temporarily_release_connection
# rubocop:disable Style/ClassAndModuleChildren
class Minitest::HooksSpec
  def around(&block)
    Paleolog::Config.db.transaction(rollback: :always, auto_savepoint: true) do |conn|
      Paleolog::Config.db.temporarily_release_connection(conn, &block)
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren

def click_action_to(name)
  click_button(class: name.split.join('-'))
end
