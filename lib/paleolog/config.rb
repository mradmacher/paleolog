# frozen_string_literal: true

require 'singleton'
require 'forwardable'
require 'sequel'
require 'logger'

module Paleolog
  class Config
    include Singleton

    def db
      @db ||= Sequel.connect(
        ENV.fetch('PALEOLOG_DB_URI', nil),
        # loggers: [Logger.new($stdout)],
        max_connections: ENV.fetch('PALEOLOG_DB_MAX_CONNECTIONS', 4),
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
