# frozen_string_literal: true

module Paleolog
  module Operation
    class Choice < BaseOperation
      CREATE_RULES = PaPa.define.(
        name: PaPa.required.(NameRules),
        field_id: PaPa.required.(IdRules),
      )

      def create(name:, field_id:)
        parameterize({ name: name, field_id: field_id }, CREATE_RULES)
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, ->(params) { repo.for(Paleolog::Choice).create(params) }) }
      end

      private

      def name_uniqueness
        lambda do |params|
          if repo.for(Paleolog::Choice).name_exists_within_field?(
            params[:name],
            params[:field_id],
          )
            { name: :taken }
          end
        end
      end
    end
  end
end
