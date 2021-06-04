# frozen_string_literal: true

require 'rom-repository'
require 'rom-changeset'

module Paleolog
  module Repository
    class Section < ROM::Repository[:sections]
      commands :create, update: :by_pk, delete: :by_pk

      def self.new(container = Paleolog::Repository::Config.db)
        super(container)
      end

      def clear
        sections.delete
      end

      def find(id)
        sections.by_pk(id).one!
      end

      def add_sample(section, attributes)
        samples.changeset(:create, attributes).associate(section).commit
      end
    end
  end
end
