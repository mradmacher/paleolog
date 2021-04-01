# frozen_string_literal: true

require 'rom-repository'
require 'rom-changeset'

module Paleolog
  module Repository
    class Species < ROM::Repository[:species]
      commands update: :by_pk, delete: :by_pk

      def find(id)
        species.combine(:group).by_pk(id).one!
      end

      def find_with_dependencies(id)
        species.combine(:group).combine(choices: [:fields]).combine(:images).by_pk(id).one!
      end

      def clear
        species.delete
      end

      def add_feature(species, choice)
        features.changeset(:create, choice_id: choice.id).associate(species).commit
      end

      def add_image(species, attributes)
        images.changeset(:create, attributes).associate(species).commit
      end

      def search_verified(filters = {})
        query = species.combine(:group).where(verified: true)
        query = query.where(group_id: filters[:group_id]) if filters[:group_id]
        query = query.where { name.ilike("%#{filters[:name]}%") } if filters[:name]
        query.to_a
      end
    end
  end
end
