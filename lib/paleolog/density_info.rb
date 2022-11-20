# frozen_string_literal: true

require 'param_param'

module Paleolog
  class DensityInfo
    include ParamParam

    Params = Rules.(
      sample_weight: Required.(IsDecimal.(Gt.(0))),
      counted_group: Required.(Any),
      marker: Required.(Any),
      marker_quantity: Required.(IsInteger.(Gt.(0))),
      occurrences: Required.(Any),
    )

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

      return nil unless can_compute_density?(
        sample_weight: sample&.weight,
        marker_quantity: marker_quantity,
        marker: marker,
        counted_group: counted_group,
        occurrences: sample_occurrences,
      )

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
        next unless can_compute_density?(
          sample_weight: sample&.weight,
          marker_quantity: marker_quantity,
          marker: marker,
          counted_group: counted_group,
          occurrences: sample_occurrences,
        )

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

    private

    def can_compute_density?(params)
      result = Params.(params)

      return false if result.failure?

      # must include marker
      unless result.value[:occurrences].any? { |occurrence|
        occurrence.species == result.value[:marker] && occurrence.quantity && occurrence.quantity.positive?
      }
        return false
      end
      true
    end

  end
end
