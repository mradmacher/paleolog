# frozen_string_literal: true

module Paleolog
  module Operation
    class Species < BaseOperation
      SEARCH_PARAMS = Params.define.(
        group_id: Params.optional.(Params.blank_to_nil_or.(Params::IdRules)),
        project_id: Params.optional.(Params.blank_to_nil_or.(Params::IdRules)),
        name: Params.optional.(Params.blank_to_nil_or.(Params::NameRules)),
        verified: Params.optional.(Params.blank_to_nil_or.(Params.bool.(Params.any))),
      )

      FIND_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
      )

      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        group_id: Params.required.(Params::IdRules),
        description: Params.optional.(Params::DescriptionRules),
        environmental_preferences: Params.optional.(Params::DescriptionRules),
        verified: Params.optional.(Params.bool.(Params.any)),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.optional.(Params::NameRules),
        group_id: Params.optional.(Params::IdRules),
        description: Params.optional.(Params::DescriptionRules),
        environmental_preferences: Params.optional.(Params::DescriptionRules),
        verified: Params.optional.(Params.bool.(Params.any)),
      )

      def find(raw_params)
        authenticate
          .and_then { parameterize(raw_params, FIND_PARAMS) }
          .and_then { authorize(_1, can_view(Paleolog::Species, :id)) }
          .and_then { carefully(_1, find_species) }
      end

      def search(raw_params)
        authenticate
          .and_then { parameterize(raw_params, SEARCH_PARAMS) }
          .and_then { carefully(_1, search_species) }
      end

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

      def find_species
        lambda do |params|
          repo.for(Paleolog::Species).find(params[:id])
        end
      end

      def search_species
        lambda do |params|
          repo.for(Paleolog::Species).search(params)
        end
      end

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
