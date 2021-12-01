# frozen_string_literal: true

require 'dry-validation'

module Paleolog
  module Contract
    class Density < Dry::Validation::Contract
      params do
        required(:sample_weight).filled(:decimal, gt?: 0)
        required(:counted_group).filled
        required(:marker).filled
        required(:marker_quantity).filled(:integer, gt?: 0)
        required(:occurrences).filled(:array)
      end

      rule(:occurrences) do
        key.failure('must include marker') unless value.any? do |occurrence|
          occurrence.species == values[:marker] && occurrence.quantity && occurrence.quantity.positive?
        end
      end
    end
  end
end
