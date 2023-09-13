# frozen_string_literal: true

module Paleolog
  module Operation
    class Field < BaseOperation
      CREATE_RULES = Pp.define.(
        name: Pp.required.(NameRules),
        group_id: Pp.required.(IdRules),
      )

      def create(name:, group_id:)
        parameterize({ name: name, group_id: group_id }, CREATE_RULES)
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, ->(params) { repo.for(Paleolog::Field).create(params) }) }
      end

      private

      def name_uniqueness
        lambda do |params|
          { name: :taken } if repo.for(Paleolog::Field).name_exists?(params[:name])
        end
      end
    end
  end
end
