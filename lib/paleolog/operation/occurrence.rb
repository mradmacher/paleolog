# frozen_string_literal: true

module Paleolog
  module Operation
    class Occurrence
      class << self
        CreateRules = Pp.define.(
          counting_id: Pp.required.(Pp.integer.(Pp.gt.(0))),
          sample_id: Pp.required.(Pp.integer.(Pp.gt.(0))),
          species_id: Pp.required.(Pp.integer.(Pp.gt.(0))),
        )

        UpdateRules = Pp.define.(
          quantity: Pp.optional.(Pp.blank_to_nil_or.(Pp.integer.(Pp.gte.(0)))),
          status: Pp.optional.((Pp.integer.(Pp.included_in.(Paleolog::Occurrence::STATUSES)))),
          uncertain: Pp.optional.(Pp.bool.(Pp.any)),
        )

        def create(counting_id:, sample_id:, species_id:)
          params, errors = CreateRules.(
            species_id: species_id,
            counting_id: counting_id,
            sample_id: sample_id,
          )
          return [nil, errors] unless errors.empty?

          if Paleolog::Repo::Occurrence.species_exists_within_counting_and_sample?(species_id, counting_id, sample_id)
            return [nil, { species_id: :taken }]
          end

          params[:rank] = (counting_id && sample_id ? max_rank(counting_id, sample_id) : 0) + 1
          params[:status] = Paleolog::Occurrence::NORMAL

          [Paleolog::Repo::Occurrence.create(params), {}]
        end

        def update(occurrence_id, status: Option.None, uncertain: Option.None, quantity: Option.None)
          params, errors = UpdateRules.(
            status: status,
            uncertain: uncertain,
            quantity: quantity,
          )
          return [nil, errors] unless errors.empty?

          [Paleolog::Repo::Occurrence.update(occurrence_id, params), {}]
        end

        private

        def max_rank(counting_id, sample_id)
          Paleolog::Repo::Occurrence
            .all_for_sample(counting_id, sample_id)
            .max_by(&:rank)&.rank || 0
        end
      end
    end
  end
end
