# frozen_string_literal: true

require 'paleolog/utils'

module Paleolog
  module Operation
    class Occurrence
      class << self
        include Validations

        CreateRules = Validate.(
          counting_id: Required.(AnyOf.([NotBlank, IsInteger.(Gt.(0))])),
          sample_id: Required.(AnyOf.([NotBlank, IsInteger.(Gt.(0))])),
          species_id: Required.(AnyOf.([NotBlank, IsInteger.(Gt.(0))])),
        )

        UpdateRules = Validate.(
          quantity: Optional.(NilOr.(IsInteger.(Gte.(0)))),
          status: Optional.((IsInteger.(IncludedIn.(Paleolog::Occurrence::STATUSES)))),
          uncertain: Optional.(IsBool),
        )

        def create(counting_id:, sample_id:, species_id:)
          result = CreateRules.(
            species_id: species_id,
            counting_id: counting_id,
            sample_id: sample_id,
          )
          return result if result.failure?

          attrs = result.value
          attrs[:rank] =
            if counting_id && sample_id
              Paleolog::Repo::Occurrence
                .all_for_sample(counting_id, sample_id)
                .max_by(&:rank)&.rank || 0
            else
              0
            end + 1
          attrs[:status] = Paleolog::Occurrence::NORMAL

          if Paleolog::Repo::Occurrence.species_exists_within_counting_and_sample?(species_id, counting_id, sample_id)
            return Failure.new({ species_id: ['is already taken'] })
          end

          Success.new(Paleolog::Repo::Occurrence.create(attrs))
        end

        def update(occurrence_id, status: Option.None, uncertain: Option.None, quantity: Option.None)
          result = UpdateRules.(
            status: status,
            uncertain: uncertain,
            quantity: quantity,
          )
          return result if result.failure?

          Success.new(Paleolog::Repo::Occurrence.update(occurrence_id, result.value))
        end
      end
    end
  end
end
