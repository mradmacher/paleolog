# frozen_string_literal: true

module Paleolog
  module Operation
    class Occurrence
      CreateParams = Dry::Schema.Params do
        required(:counting_id).filled(:integer)
        required(:sample_id).filled(:integer)
        required(:species_id).filled(:integer)
      end

      UpdateParams = Dry::Schema.Params do
        optional(:quantity).maybe(:integer, gteq?: 0)
        optional(:status).filled(
          :integer,
          included_in?: [
            Paleolog::CountingSummary::NORMAL,
            Paleolog::CountingSummary::OUTSIDE_COUNT,
            Paleolog::CountingSummary::CARVING,
            Paleolog::CountingSummary::REWORKING
          ],
        )
        optional(:uncertain).filled(:bool)
      end

      class << self
        def create(counting_id:, sample_id:, species_id:)
          params = {
            species_id: species_id,
            counting_id: counting_id,
            sample_id: sample_id,
          }

          errors = CreateParams.call(params).errors
          return Failure.new(errors.to_h) if errors.any?

          params[:rank] =
            if counting_id && sample_id
              Paleolog::Repo::Occurrence
                .all_for_sample(counting_id, sample_id)
                .max_by(&:rank)&.rank || 0
            else
              0
            end + 1
          params[:status] = Paleolog::CountingSummary::NORMAL

          if Paleolog::Repo::Occurrence.species_exists_within_counting_and_sample?(species_id, counting_id, sample_id)
            return Failure.new({ species_id: ['is already taken'] })
          end

          Success.new(Paleolog::Repo::Occurrence.create(params))
        end

        def update(occurrence_id, status: None, uncertain: None, quantity: None)
          params = {}

          params[:status] = status unless status == None
          params[:uncertain] = uncertain unless uncertain == None
          params[:quantity] = quantity unless quantity == None

          errors = UpdateParams.call(params).errors
          return Failure.new(errors.to_h) if errors.any?

          Success.new(Paleolog::Repo::Occurrence.update(occurrence_id, params))
        end
      end
    end
  end
end
