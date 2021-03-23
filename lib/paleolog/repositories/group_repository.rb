# frozen_string_literal: true

require 'rom-repository'

module Paleolog
  module Repositories
    # Paleolog::Repository
    class GroupRepository < ROM::Repository[:groups]
      struct_namespace Paleolog
      commands :create, update: :by_pk, delete: :by_pk

      def clear
        groups.delete
      end

      def find(id)
        groups.by_pk(id).one!
      end

      def all
        groups.to_a
      end

      def add_species(group, attributes)
        # species.combine(:group).command(:create).call(attributes.merge(group_id: group.id))
        species.changeset(:create, attributes).associate(group).commit
      end
    end
  end
end
