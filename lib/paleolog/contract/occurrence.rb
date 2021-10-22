# frozen_string_literal: true

require 'dry-validation'

module Paleolog
  module Contract
    class Occurrence < Dry::Validation::Contract
      option :occurrence_repo

      params(Contract::OccurrenceSchema)

      rule(:rank) do
        key.failure('is already taken') if occurrence_repo.rank_exists_within_counting_and_sample?(value, values[:counting_id], values[:sample_id])
      end

      rule(:species_id) do
        key.failure('is already taken') if occurrence_repo.species_exists_within_counting_and_sample?(value, values[:counting_id], values[:sample_id])
      end
    end
  end
end
