# frozen_string_literal: true

require 'param_param'

module Paleolog
  module Operation
    class Project
      class << self
        include ParamParam

        ProjectRules = Rules.(
          name: Required.(IsString.(AllOf.([Stripped, NotBlank, MaxSize.(255)])))
        )

        def create(name:)
          result = ProjectRules.(name: name)
          return result if result.failure?

          if Paleolog::Repo::Project.name_exists?(result.value[:name])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Project.create(result.value))
        end
      end
    end
  end
end
