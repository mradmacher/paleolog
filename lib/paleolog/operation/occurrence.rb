# frozen_string_literal: true

module Paleolog
  module Operation
    class Occurrence < BaseOperation
      CREATE_PARAMS = Params.define.(
        counting_id: Params.required.(Params::IdRules),
        sample_id: Params.required.(Params::IdRules),
        species_id: Params.required.(Params::IdRules),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        quantity: Params.optional.(Params.blank_to_nil_or.(Params.integer.(Params.gte.(0)))),
        status: Params.optional.(Params.integer.(Params.included_in.(Paleolog::Occurrence::STATUSES))),
        uncertain: Params.optional.(Params.bool.(Params.any)),
      )

      def create(raw_params)
        parameterize(raw_params, CREATE_PARAMS)
          .and_then { verify(_1, species_uniqueness) }
          .and_then { merge(_1, default_status) }
          .and_then { merge(_1, next_rank) }
          .and_then { carefully(_1, save_occurrence) }
      end

      def update(raw_params)
        parameterize(raw_params, UPDATE_PARAMS)
          .and_then { carefully(_1, save_occurrence) }
      end

      private

      def save_occurrence
        lambda do |params|
          repo.find(
            Paleolog::Occurrence,
            repo.save(Paleolog::Occurrence.new(**params)),
          )
        end
      end

      def species_uniqueness
        lambda do |params|
          if repo.for(Paleolog::Occurrence).species_exists_within_counting_and_sample?(
            params[:species_id],
            params[:counting_id],
            params[:sample_id],
          )
            { species_id: TAKEN }
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
