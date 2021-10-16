# frozen_string_literal: true

module Paleolog
  module Repo
    class Section
      def delete_all
        Entity.dataset.delete
      end

      def find(id)
        Entity[id]
      end

      def find_sample(section, id)
        Sample::Entity.where(section_id: section.id, id: id).first
      end

      def add_sample(section, attributes)
        Sample::Entity.create(attributes.merge(section_id: section.id))
      end

      class Entity < Sequel::Model(Config.db[:sections])
        one_to_many :samples, class: 'Paleolog::Repo::Sample::Entity', key: :section_id
      end
    end
  end
end
