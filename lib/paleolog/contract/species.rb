# frozen_string_literal: true

require 'dry-validation'

module Paleolog
  module Contract
    class Species < Dry::Validation::Contract
      option :species_repo

      params(SpeciesSchema)

      rule(:name) do
        key.failure('is already taken') if species_repo.name_exists_within_group?(value, values[:group_id])
      end
    end
  end
end
