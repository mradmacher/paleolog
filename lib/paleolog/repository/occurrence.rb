# frozen_string_literal: true

require 'rom-repository'
require 'rom-changeset'

module Paleolog
  module Repository
    class Occurrence < ROM::Repository[:occurrences]
      commands :create, update: :by_pk, delete: :by_pk

      def self.new(container = Paleolog::Repository::Config.db)
        super(container)
      end

      def clear
        occurrences.delete
      end

      def all_for_sample(counting, sample)
        occurrences.where(counting_id: counting.id, sample_id: sample.id).combine(species: [:group]).order { rank.desc }.to_a
      end

      def all_for_section(counting, section)
        occurrences.where(counting_id: counting.id, sample_id: section.samples.map(&:id)).combine(species: [:group, :choices]).order { rank.desc }.to_a
      end
    end
  end
end
