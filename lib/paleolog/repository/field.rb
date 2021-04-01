# frozen_string_literal: true

require 'rom-repository'
require 'rom-changeset'

module Paleolog
  module Repository
    class Field < ROM::Repository[:fields]
      commands update: :by_pk, delete: :by_pk

      def clear
        fields.delete
      end

      def add_choice(field, attributes)
        choices.changeset(:create, attributes).associate(field).commit
      end
    end
  end
end
