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

      def find(id)
        countings.by_pk(id).one!
      end
    end
  end
end
