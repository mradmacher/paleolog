# frozen_string_literal: true

require 'dry-validation'

module Paleolog
  module Contract
    class Group < Dry::Validation::Contract
      option :group_repo

      params do
        required(:name).value(Contract::Types::StrippedString, :filled?, max_size?: 255)
      end

      rule(:name) do
        key.failure('is already taken') if group_repo.name_exists?(value)
      end
    end
  end
end
