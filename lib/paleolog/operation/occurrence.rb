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
          return Failure.new(errors) unless errors.empty?

          params[:rank] =
            if counting_id && sample_id
              Paleolog::Repo::Occurrence
                .all_for_sample(counting_id, sample_id)
                .max_by(&:rank)&.rank || 0
            else
              0
            end + 1
          params[:status] = Paleolog::Occurrence::NORMAL

          if Paleolog::Repo::Occurrence.species_exists_within_counting_and_sample?(species_id, counting_id, sample_id)
            return Failure.new({ species_id: :taken })
          end

          Success.new(Paleolog::Repo::Occurrence.create(params))
        end

        def update(occurrence_id, status: Option.None, uncertain: Option.None, quantity: Option.None)
          params, errors = UpdateRules.(
            status: status,
            uncertain: uncertain,
            quantity: quantity,
          )
          return Failure.new(errors) unless errors.empty?

          Success.new(Paleolog::Repo::Occurrence.update(occurrence_id, params))
        end
      end
    end
  end
end
