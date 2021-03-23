# frozen_string_literal: true

require 'rom-repository'

module Paleolog
  module Repositories
    class SpeciesRepository < ROM::Repository[:species]
      struct_namespace Paleolog
      commands update: :by_pk, delete: :by_pk

      def find(id)
        species.combine(:group).by_pk(id).one!
      end

      def clear
        species.delete
      end

      def create(new_species)
        species.changeset(:create, new_species.to_h).associate(new_species.group).commit
      end

      def search_verified(filters = {})
        # Paleolog::Group.schema.keys.map(&:name)
        query = species.combine(:group).where(verified: true)
        query = query.where(group_id: filters[:group_id]) if filters[:group_id]
        query = query.where { name.ilike("%#{filters[:name]}%") } if filters[:name]
        query.to_a
      end
    end
  end
end
