# frozen_string_literal: true

module Paleolog
  module Operation
    class Occurrence < BaseOperation
      CREATE_RULES = Pp.define.(
        counting_id: Pp.required.(IdRules),
        sample_id: Pp.required.(IdRules),
        species_id: Pp.required.(IdRules),
      )

      UPDATE_RULES = Pp.define.(
        quantity: Pp.optional.(Pp.blank_to_nil_or.(Pp.integer.(Pp.gte.(0)))),
        status: Pp.optional.((Pp.integer.(Pp.included_in.(Paleolog::Occurrence::STATUSES)))),
        uncertain: Pp.optional.(Pp.bool.(Pp.any)),
      )

      def create(raw_params)
        parameterize(raw_params, CREATE_RULES)
          .and_then { verify(_1, species_uniqueness) }
          .and_then { merge(_1, default_status) }
          .and_then { merge(_1, next_rank) }
          .and_then { carefully(_1, create_occurrence) }
      end

      def update(occurrence_id, **raw_params)
        parameterize(raw_params, UPDATE_RULES)
          .and_then { carefully(_1, ->(params) { repo.for(Paleolog::Occurrence).update(occurrence_id, params) }) }
      end

      private

      def create_occurrence
        lambda do |params|
          repo.for(Paleolog::Occurrence).create(params)
        end
      end

      def species_uniqueness
        lambda do |params|
          if repo.for(Paleolog::Occurrence).species_exists_within_counting_and_sample?(
            params[:species_id],
            params[:counting_id],
            params[:sample_id],
          )
            { species_id: :taken }
          end
        end
      end

      def default_status
        lambda do |params|
          { status: Paleolog::Occurrence::NORMAL }
        end
      end

      def next_rank
        lambda do |params|
          max_rank = repo.for(Paleolog::Occurrence)
              .all_for_sample(params[:counting_id], params[:sample_id])
              .max_by(&:rank)&.rank || 0
          { rank: max_rank + 1 }
        end
      end
    end
  end
end
