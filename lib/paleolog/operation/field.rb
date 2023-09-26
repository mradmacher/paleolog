# frozen_string_literal: true

module Paleolog
  module Operation
    class Field < BaseOperation
      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        group_id: Params.required.(Params::IdRules),
      )

      def create(name:, group_id:)
        parameterize({ name: name, group_id: group_id }, CREATE_PARAMS)
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, ->(params) { repo.for(Paleolog::Field).create(params) }) }
      end

      private

      def name_uniqueness
        lambda do |params|
          { name: TAKEN } if repo.for(Paleolog::Field).name_exists?(params[:name])
        end
      end
    end
  end
end
