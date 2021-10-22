# frozen_string_literal: true

require 'dry-validation'

module Paleolog
  module Contract
    class Group < Dry::Validation::Contract
      option :group_repo

      params(Contract::GroupSchema)

      rule(:name) do
        key.failure('is already taken') if group_repo.name_exists?(value)
      end
    end
  end
end
