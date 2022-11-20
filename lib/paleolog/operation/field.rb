# frozen_string_literal: true

require 'param_param'

module Paleolog
  module Operation
    class Field
      class << self
        include ParamParam

        FieldRules = Rules.(
          name: Required.(IsString.(AllOf.([Stripped, NotBlank, MaxSize.(255)]))),
          group_id: Required.(IsInteger.(Gt.(0)))
        )

        def create(name:, group_id:)
          result = FieldRules.(name: name, group_id: group_id)
          return result if result.failure?

          if Paleolog::Repo::Field.name_exists?(result.value[:name])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Field.create(result.value))
        end
      end
    end
  end
end
