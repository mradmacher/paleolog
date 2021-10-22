# frozen_string_literal: true

require 'dry-validation'

module Paleolog
  module Contract
    class Section < Dry::Validation::Contract
      option :section_repo

      params(Contract::SectionSchema)

      rule(:name) do
        key.failure('is already taken') if section_repo.name_exists_within_project?(value, values[:project_id])
      end
    end
  end
end
