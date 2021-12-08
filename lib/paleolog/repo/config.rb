# frozen_string_literal: true

require 'singleton'
require 'forwardable'
require 'sequel'
require 'logger'

module Paleolog
  module Repo
    class Config
      include Singleton

      def db
        @db ||= Sequel.connect(
          "sqlite:#{File.expand_path(File.join(__dir__, '..', '..', '..', 'db',
                                               "#{ENV['RACK_ENV']}.sqlite",))}",
          # loggers: [Logger.new($stdout)],
        )
      end

      class << self
        extend Forwardable

        def_delegators(
          :instance,
          :db,
        )
      end
    end
  end
end
