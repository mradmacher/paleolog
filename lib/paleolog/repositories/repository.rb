# frozen_string_literal: true

require 'singleton'
require 'forwardable'
require 'rom-sql'

module Paleolog
  module Repositories
    class Repository
      include Singleton

      def configuration
        @configuration = ROM::Configuration.new(:sql,
                                                "sqlite:#{File.expand_path(File.join(__dir__, '..', '..', '..', 'db',
                                                                                     "#{ENV['RACK_ENV']}.sqlite"))}").tap do |conf|
          conf.relation(:groups) do
            schema(infer: true) do
              associations do
                has_many :species
              end
            end
          end

          conf.relation(:species) do
            schema(infer: true) do
              associations do
                belongs_to :group
              end
            end
          end
        end
      end

      def db
        @db = ROM.container(configuration)
      end

      class << self
        extend Forwardable

        def_delegators(
          :instance,
          :configuration,
          :db
        )
      end
    end
  end
end
