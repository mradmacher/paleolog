# frozen_string_literal: true

require 'paleolog/utils'

module Paleolog
  module Operation
    class Field
      class << self
        include Validations

        FieldParams = Validate.(
          name: Required.(IsString.(AnyOf.([Stripped, NotBlank, MaxSize.(255)]))),
          group_id: Required.(IsInteger.(Gt.(0)))
        )

        def create(name:, group_id:)
          result = FieldParams.(name: name, group_id: group_id)
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
