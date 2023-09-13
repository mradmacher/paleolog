# frozen_string_literal: true

module Paleolog
  module Operation
    class Group < BaseOperation
      CREATE_RULES = Pp.define.(
        name: Pp.required.(NameRules),
      )

      def create(name:)
        parameterize({ name: name }, CREATE_RULES)
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, ->(params) { repo.for(Paleolog::Group).create(params) }) }
      end

      private

      def name_uniqueness
        lambda do |params|
          { name: :taken } if repo.for(Paleolog::Group).name_exists?(params[:name])
        end
      end
    end
  end
end
