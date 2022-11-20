# frozen_string_literal: true

require 'param_param'

module Paleolog
  module Operation
    class Choice
      class << self
        include ParamParam

        ChoiceRules = Rules.(
          name: Required.(IsString.(AllOf.([Stripped, NotBlank, MaxSize.(255)]))),
          field_id: Required.(IsInteger.(Gt.(0)))
        )

        def create(name:, field_id:)
          result = ChoiceRules.(name: name, field_id: field_id)
          return result if result.failure?

          if Paleolog::Repo::Choice.name_exists_within_field?(result.value[:name], result.value[:field_id])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Choice.create(result.value))
        end
      end
    end
  end
end
