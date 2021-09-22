# frozen_string_literal: true

module Paleolog
  module Repo
    class Counting
      def find(id)
        Entity[id]
      end

      def update(id, attributes)
        Entity.where(id: id).update(attributes)
        find(id)
      end

      class Entity < Sequel::Model(Config.db[:countings])
        many_to_one :project, class: 'Paleolog::Repo::Project::Entity', key: :project_id
        many_to_one :group, class: 'Paleolog::Repo::Group::Entity', key: :group_id
        many_to_one :species, class: 'Paleolog::Repo::Species::Entity', key: :marker_id
        one_to_many :occurrences, class: 'Paleolog::Repo::Occurrence::Entity', key: :counting_id
      end
    end
  end
end
