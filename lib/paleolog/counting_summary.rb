# frozen_string_literal: true

module Paleolog
  class CountingSummary
    attr_reader :occurrences

    STATUSES = {
      Paleolog::Occurrence::NORMAL => '',
      Paleolog::Occurrence::OUTSIDE_COUNT => '+',
      Paleolog::Occurrence::CARVING => 'c',
      Paleolog::Occurrence::REWORKING => 'r',
    }.freeze
    UNCERTAIN_SYMBOL = '?'

    def initialize(occurrences)
      @occurrences = occurrences
    end

    def countable_sum
      occurrences
        .select { |occ| occ.status == Paleolog::Occurrence::NORMAL }
        .map { |occ| occ.quantity.to_i }.sum
    end

    def uncountable_sum
      occurrences
        .reject { |occ| occ.status == Paleolog::Occurrence::NORMAL }
        .map { |occ| occ.quantity.to_i }.sum
    end

    def total_sum
      occurrences.map { |occ| occ.quantity.to_i }.sum
    end

    def self.status_symbol(status)
      STATUSES[status]
    end

    # occurrence: in: [:first, :last]
    def summary(samples, occurrence: :first)
      samples_summary = samples.sort_by(&:rank)

      species_summary = specimens_by_occurrence(
        occurrence == :first ? samples_summary : samples_summary.reverse,
      )

      occurrences_summary = Array.new(samples_summary.size) { Array.new(species_summary.size) }
      occurrences.each do |occr|
        row = samples_summary.index(occr.sample)
        column = species_summary.index(occr.species)
        occurrences_summary[row][column] = occr
      end

      [samples_summary, species_summary, occurrences_summary]
    end

    def specimens_by_occurrence_for_section(counting, section)
      specimens_by_occurrence(counting, section.samples.sort_by(&:rank))
    end

    def specimens_by_occurrence(samples)
      specimens = []
      samples.each do |sample|
        specimens +=
          occurrences
          .select { |occ| occ.sample == sample }
          .reject { |occ| specimens.include?(occ.species) }
          .sort_by(&:rank)
          .map(&:species)
      end
      specimens
    end

    private

    def filter_occurrences(counting, sample)
      occurrences.select { |occ| occ.sample == sample && occ.counting == counting }
    end

    def can_compute_density?(counting, sample)
      counting.group_id && counting.marker_id && counting.marker_count && sample.weight && !sample.weight.zero?
    end
  end
end
