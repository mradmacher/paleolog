# frozen_string_literal: true

require 'param_param'
require 'param_param/std'

module Paleolog
  class DensityInfo
    class DensityParams
      include ParamParam
      include ParamParam::Std

      RULES = define do |p|
        {
          sample_weight: p::REQUIRED.(p::ALL_OF.([p::DECIMAL, p::GT.(0)])),
          marker_added: p::REQUIRED.(p::ALL_OF.([p::INTEGER, p::GT.(0)])),
          marker_counted: p::REQUIRED.(p::ALL_OF.([p::INTEGER, p::GT.(0)])),
          occurrences: p::REQUIRED.(p::ANY),
        }
      end

      def self.verify(params)
        RULES.(params)
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def group_density(occurrences, sample)
      sample_occurrences = occurrences.select { it.sample == sample }
      marker_counted = sample_occurrences.select(&:marker?).map(&:quantity).sum

      return nil unless can_compute_density?(
        sample_weight: sample&.weight,
        marker_added: sample&.marker_quantity,
        marker_counted: marker_counted,
        occurrences: sample_occurrences,
      )

      counted_group_quantity = sample_occurrences.select(&:normal?).map(&:quantity).sum * 1.0

      (counted_group_quantity / marker_counted) * (sample.marker_quantity / sample.weight)
    end

    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def occurrence_density_map(occurrences, samples)
      density_map = []

      samples.each do |sample|
        sample_occurrences = occurrences.select { it.sample == sample }
        marker_counted = sample_occurrences.select(&:marker?).map(&:quantity).compact.sum
        next unless can_compute_density?(
          sample_weight: sample&.weight,
          marker_added: sample&.marker_quantity,
          marker_counted: marker_counted,
          occurrences: sample_occurrences,
        )

        sample_occurrences.select(&:normal?).each do |occ|
          occ_quantity = (occ.quantity || 0) * 1.0
          density_map << [
            occ,
            ((occ_quantity / marker_counted) * (sample.marker_quantity / sample.weight)).to_f
          ]
        end
      end
      density_map
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity

    private

    def can_compute_density?(params)
      _, errors = DensityParams.verify(params)

      errors.empty?
    end
  end
end
