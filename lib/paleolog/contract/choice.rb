# frozen_string_literal: true

require 'dry-validation'

module Paleolog
  module Contract
    class Choice < Dry::Validation::Contract
      option :choice_repo

      params(Contract::ChoiceSchema)

      rule(:name) do
        key.failure('is already taken') if choice_repo.name_exists_within_field?(value, values[:field_id])
      end
    end
  end
end
