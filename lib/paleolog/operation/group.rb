# frozen_string_literal: true

require 'param_param'

module Paleolog
  module Operation
    class Group
      class << self
        include ParamParam

        GroupRules = Rules.(
          name: Required.(IsString.(AllOf.([Stripped, NotBlank, MaxSize.(255)])))
        )

        def create(name:)
          result = GroupRules.(name: name)
          return result if result.failure?

          if Paleolog::Repo::Group.name_exists?(result.value[:name])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Group.create(result.value))
        end
      end
    end
  end
end
