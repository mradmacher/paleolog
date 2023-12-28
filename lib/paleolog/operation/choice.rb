# frozen_string_literal: true

module Paleolog
  module Operation
    class Choice < BaseOperation
      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        field_id: Params.required.(Params::IdRules),
      )

      def create(name:, field_id:)
        parameterize({ name: name, field_id: field_id }, CREATE_PARAMS)
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, save_choice) }
      end

      private

      def save_choice
        lambda do |params|
          repo.find(
            Paleolog::Choice,
            repo.save(Paleolog::Choice.new(**params)),
          )
        end
      end

      def name_uniqueness
        lambda do |params|
          if repo.for(Paleolog::Choice).name_exists_within_field?(
            params[:name],
            params[:field_id],
          )
            { name: TAKEN }
          end
        end
      end
    end
  end
end
