# frozen_string_literal: true

module Paleolog
  module Operation
    class Species < BaseOperation
      CREATE_RULES = Pp.define.(
        name: Pp.required.(NameRules),
        group_id: Pp.required.(IdRules),
        description: Pp.optional.(DescriptionRules),
        environmental_preferences: Pp.optional.(DescriptionRules),
      )

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_RULES) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, create_species) }
      end

      private

      def create_species
        ->(params) { repo.for(Paleolog::Species).create(params) }
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          if repo.for(Paleolog::Species).name_exists_within_group?(
            params[:name],
            params[:group_id],
            exclude_id: params[:id],
          )
            { name: :taken }
          end
        end
      end
    end
  end
end
