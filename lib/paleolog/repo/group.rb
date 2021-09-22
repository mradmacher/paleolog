# frozen_string_literal: true

module Paleolog
  module Repo
    class Group
      def delete_all
        Entity.dataset.delete
      end

      def create(attributes)
        Entity.create(attributes)
      end

      def find(id)
        Entity[id]
      end

      def all
        Entity.dataset.all
      end

      def add_species(group, attributes)
        Species::Entity.create(attributes.merge(group_id: group.id))
      end

      def add_field(group, attributes)
        Field::Entity.create(attributes.merge(group_id: group.id))
      end

      private

      class Entity < Sequel::Model(Config.db[:groups])
        one_to_many :species
        one_to_many :fields
      end
    end
  end
end
