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
          ENV.fetch('PALEOLOG_DB_URI', nil),
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
