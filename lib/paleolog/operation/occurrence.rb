# frozen_string_literal: true

module Paleolog
  module Operation
    class Occurrence < BaseOperation
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

        if repo.for(Paleolog::Occurrence).species_exists_within_counting_and_sample?(species_id, counting_id, sample_id)
          return Failure.new(species_id: :taken)
        end

        params[:rank] = (counting_id && sample_id ? max_rank(counting_id, sample_id) : 0) + 1
        params[:status] = Paleolog::Occurrence::NORMAL

        Success.new(repo.for(Paleolog::Occurrence).create(params))
      end

      def update(occurrence_id, status: Optiomist.none, uncertain: Optiomist.none, quantity: Optiomist.none)
        params, errors = UpdateRules.(
          status: status,
          uncertain: uncertain,
          quantity: quantity,
        )
        return Failure.new(errors) unless errors.empty?

        Success.new(repo.for(Paleolog::Occurrence).update(occurrence_id, params))
      end

      private

      def max_rank(counting_id, sample_id)
        repo.for(Paleolog::Occurrence)
            .all_for_sample(counting_id, sample_id)
            .max_by(&:rank)&.rank || 0
      end
    end
  end
end
