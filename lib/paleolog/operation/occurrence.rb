# frozen_string_literal: true

module Paleolog
  module Operation
    class Occurrence < BaseOperation
      CREATE_RULES = PaPa.define.(
        counting_id: PaPa.required.(IdRules),
        sample_id: PaPa.required.(IdRules),
        species_id: PaPa.required.(IdRules),
      )

      UPDATE_RULES = PaPa.define.(
        quantity: PaPa.optional.(PaPa.blank_to_nil_or.(PaPa.integer.(PaPa.gte.(0)))),
        status: PaPa.optional.((PaPa.integer.(PaPa.included_in.(Paleolog::Occurrence::STATUSES)))),
        uncertain: PaPa.optional.(PaPa.bool.(PaPa.any)),
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
        lambda do |_|
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
