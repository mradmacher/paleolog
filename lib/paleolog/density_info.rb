# frozen_string_literal: true

module Paleolog
  class DensityInfo
    attr_reader :counted_group,
                :marker,
                :marker_quantity

    def initialize(counted_group:, marker:, marker_quantity:)
      @counted_group = counted_group
      @marker = marker
      @marker_quantity = marker_quantity
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def group_density(occurrences, sample)
      sample_occurrences = occurrences.select { |occ| occ.sample == sample }

      return nil unless Paleolog::Contract::Density.new.call(
        sample_weight: sample&.weight,
        marker_quantity: marker_quantity,
        marker: marker,
        counted_group: counted_group,
        occurrences: sample_occurrences,
      ).errors.empty?

      counted_marker_quantity = sample_occurrences.select { |occ| occ.species == marker }.map(&:quantity).sum

      counted_group_quantity = sample_occurrences.select do |occ|
        occ.species.group == counted_group
      end.map(&:quantity).sum * 1.0

      (counted_group_quantity / counted_marker_quantity) * (marker_quantity / sample.weight)
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def occurrence_density_map(occurrences, samples)
      density_map = []

      samples.each do |sample|
        sample_occurrences = occurrences.select { |occ| occ.sample == sample }
        next unless Paleolog::Contract::Density.new.call(
          sample_weight: sample.weight,
          marker_quantity: marker_quantity,
          marker: marker,
          counted_group: counted_group,
          occurrences: sample_occurrences,
        ).errors.empty?

        marker_cnt = sample_occurrences.select { |occ| occ.species == marker }.map(&:quantity).compact.sum

        sample_occurrences.select { |occ| occ.species.group == counted_group }.each do |occ|
          density_map << [occ, (((occ.quantity || 0) * 1.0) / marker_cnt) * (marker_quantity / sample.weight)]
        end
      end
      density_map
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end