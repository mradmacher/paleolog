# frozen_string_literal: true

require 'rom-repository'
require 'rom-changeset'

module Paleolog
  module Repository
    class Group < ROM::Repository[:groups]
      commands :create, update: :by_pk, delete: :by_pk

      def clear
        groups.delete
      end

      def find(id)
        groups.by_pk(id).one!
      end

      def all
        groups.to_a
      end

      def add_species(group, attributes)
        species.changeset(:create, attributes).associate(group).commit
      end

      def add_field(group, attributes)
        fields.changeset(:create, attributes).associate(group).commit
      end
    end
  end
end
