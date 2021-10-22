# frozen_string_literal: true

require 'dry-validation'

module Paleolog
  module Contract
    class Sample < Dry::Validation::Contract
      option :sample_repo

      params(Contract::SampleSchema)

      rule(:name) do
        key.failure('is already taken') if sample_repo.name_exists_within_section?(value, values[:section_id])
      end

      rule(:rank) do
        key.failure('is already taken') if sample_repo.rank_exists_within_section?(value, values[:section_id])
      end
    end
  end
end
