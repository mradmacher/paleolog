# frozen_string_literal: true

require 'paleolog/utils'

module Paleolog
  module Operation
    class Species
      class << self
        include Validations

        Params = Validate.(
          name: Required.(IsString.(AnyOf.([Stripped, NotBlank, MaxSize.(255)]))),
          group_id: Required.(IsInteger.(Gt.(0))),
          description: Optional.(NilOr.(IsString.(MaxSize.(4096)))),
          environmental_preferences: Optional.(NilOr.(IsString.(MaxSize.(4096)))),
        )

        def create(name:, group_id:, description: Option.None, environmental_preferences: Option.None)
          result = Params.(
            name: name,
            group_id: group_id,
            description: description,
            environmental_preferences: environmental_preferences,
          )
          return result if result.failure?

          if Paleolog::Repo::Species.name_exists_within_group?(result.value[:name], result.value[:group_id])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Species.create(result.value))
        end
      end
    end
  end
end
