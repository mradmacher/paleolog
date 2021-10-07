# frozen_string_literal: true

module Paleolog
  module Repo
    class Sample
      def delete_all
        Entity.dataset.delete
      end

      def find(id)
        Entity[id]
      end

      def for_section(section)
        Entity.where(section_id: section.id).to_a
      end

      def update(id, attributes)
        Entity.where(id: id).update(attributes)
        find(id)
      end

      private

      class Entity < Sequel::Model(Config.db[:samples])
        many_to_one :section, class: 'Paleolog::Repo::Section::Entity', key: :section_id
      end
    end
  end
end
