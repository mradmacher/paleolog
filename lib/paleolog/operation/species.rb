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
          .and_then { carefully(_1, create_species) }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, update_species) }
      end

      private

      def create_species
        ->(params) { repo.for(Paleolog::Species).create(params) }
      end

      def update_species
        ->(params) { repo.for(Paleolog::Species).update(params[:id], params.except(:id)) }
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          if repo.for(Paleolog::Species).name_exists_within_group?(
            params[:name],
            params[:group_id],
            exclude_id: params[:id],
          )
            { name: TAKEN }
          end
        end
      end
    end
  end
end
