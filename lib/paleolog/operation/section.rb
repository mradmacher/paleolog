# frozen_string_literal: true

require 'paleolog/utils'

module Paleolog
  module Operation
    class Section
      class << self
        include Validations

        SectionParams = Validate.(
          name: Required.(IsString.(AnyOf.([Stripped, NotBlank, MaxSize.(255)]))),
          project_id: Required.(IsInteger.(Gt.(0)))
        )

        def create(name:, project_id:)
          result = SectionParams.(name: name, project_id: project_id)
          return result if result.failure?

          if Paleolog::Repo::Section.name_exists_within_project?(result.value[:name], result.value[:project_id])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Section.create(result.value))
        end
      end
    end
  end
end

