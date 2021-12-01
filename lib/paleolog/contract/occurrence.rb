# frozen_string_literal: true

require 'dry-validation'

module Paleolog
  module Contract
    class Occurrence < Dry::Validation::Contract
      option :occurrence_repo

      params(Contract::OccurrenceSchema)

      rule(:rank) do
        if occurrence_repo.rank_exists_within_counting_and_sample?(value, values[:counting_id], values[:sample_id])
          key.failure('is already taken')
        end
      end

      rule(:species_id) do
        if occurrence_repo.species_exists_within_counting_and_sample?(value, values[:counting_id], values[:sample_id])
          key.failure('is already taken')
        end
      end
    end
  end
end
