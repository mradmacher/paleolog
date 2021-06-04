# frozen_string_literal: true

require 'rom-repository'
require 'rom-changeset'

module Paleolog
  module Repository
    class Counting < ROM::Repository[:countings]
      commands update: :by_pk, delete: :by_pk

      def self.new(container = Paleolog::Repository::Config.db)
        super(container)
      end
    end
  end
end
