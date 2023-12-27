# frozen_string_literal: true

module Paleolog
  module Operation
    class Species < BaseOperation
      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        group_id: Params.required.(Params::IdRules),
        description: Params.optional.(Params::DescriptionRules),
        environmental_preferences: Params.optional.(Params::DescriptionRules),
      )
      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.optional.(Params::NameRules),
        group_id: Params.optional.(Params::IdRules),
        description: Params.optional.(Params::DescriptionRules),
        environmental_preferences: Params.optional.(Params::DescriptionRules),
      )

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_PARAMS) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, save_species) }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, save_species) }
      end

      private

      def save_species
        lambda do |params|
          repo.find(
            Paleolog::Species,
            repo.save(Paleolog::Species.new(**params)),
          )
        end
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          if repo.for(Paleolog::Species).name_exists?(
            params[:name],
            exclude_id: params[:id],
          )
            { name: TAKEN }
          end
        end
      end
    end
  end
end
