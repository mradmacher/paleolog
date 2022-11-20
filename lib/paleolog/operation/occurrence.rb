# frozen_string_literal: true

require 'param_param'

module Paleolog
  module Operation
    class Occurrence
      class << self
        include ParamParam

        CreateRules = Rules.(
          counting_id: Required.(IsInteger.(Gt.(0))),
          sample_id: Required.(IsInteger.(Gt.(0))),
          species_id: Required.(IsInteger.(Gt.(0))),
        )

        UpdateRules = Rules.(
          quantity: Optional.(BlankToNilOr.(IsInteger.(Gte.(0)))),
          status: Optional.((IsInteger.(IncludedIn.(Paleolog::Occurrence::STATUSES)))),
          uncertain: Optional.(IsBool.(Any)),
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
            return Failure.new({ species_id: :taken })
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
