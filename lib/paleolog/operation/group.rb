# frozen_string_literal: true

module Paleolog
  module Operation
    class Group < BaseOperation
      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
      )

      def create(name:)
        parameterize({ name: name }, CREATE_PARAMS)
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, save_group) }
      end

      private

      def save_group
        lambda do |params|
          repo.find(
            Paleolog::Group,
            repo.save(Paleolog::Group.new(**params)),
          )
        end
      end

      def name_uniqueness
        lambda do |params|
          { name: TAKEN } if repo.for(Paleolog::Group).name_exists?(params[:name])
        end
      end
    end
  end
end
