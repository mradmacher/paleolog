# frozen_string_literal: true

require 'dry-validation'

module Paleolog
  module Contract
    class Project < Dry::Validation::Contract
      option :project_repo

      params(ProjectSchema)

      rule(:name) do
        key.failure('is already taken') if project_repo.name_exists?(value)
      end
    end
  end
end
