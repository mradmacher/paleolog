# frozen_string_literal: true

require 'rom-repository'
require 'rom-changeset'

module Paleolog
  module Repository
    class Sample < ROM::Repository[:samples]
      commands update: :by_pk, delete: :by_pk

      def self.new(container = Paleolog::Repository::Config.db)
        super(container)
      end

      def for_section(section)
        samples.where(section_id: section.id).to_a
      end
    end
  end
end
