# frozen_string_literal: true

module Paleolog
  module Repo
    class Field
      def all
        Entity.dataset.all
      end

      def create(attributes)
        Entity.create(attributes)
      end

      def find_by_id(id)
        Entity[id]
      end

      def find_all_with_choices
        Entity.eager(:choices).all
      end

      def add_choice(field, attributes)
        Choice::Entity.create(attributes.merge(field_id: field.id))
      end

      class Entity < Sequel::Model(Config.db[:fields])
        many_to_one :group, class: 'Paleolog::Repo::Group::Entity', key: :group_id
        one_to_many :choices, class: 'Paleolog::Repo::Choice::Entity', key: :field_id
      end
    end
  end
end
