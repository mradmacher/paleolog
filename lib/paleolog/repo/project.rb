# frozen_string_literal: true

module Paleolog
  module Repo
    class Project
      def delete_all
        Entity.dataset.delete
      end

      def find(id)
        Entity[id]
      end

      def create(attributes)
        Entity.create(attributes)
      end

      def find_section(project, id)
        Section::Entity.where(project_id: project.id, id: id).first
      end

      def add_section(project, attributes)
        Section::Entity.create(attributes.merge(project_id: project.id))
      end

      def find_counting(project, id)
        Counting::Entity.where(project_id: project.id, id: id).first
      end

      def add_counting(project, attributes)
        Counting::Entity.create(attributes.merge(project_id: project.id))
      end

      def find_with_dependencies(id)
        find(id)
      end

      def all
        Entity.dataset.all
      end

      class Entity < Sequel::Model(Config.db[:projects])
        many_to_many :users, class: 'Paleolog::Repo::User::Entity', left_key: :project_id, right_key: :user_id,
                             join_table: :research_participations
        one_to_many :sections, class: 'Paleolog::Repo::Section::Entity', key: :project_id
        one_to_many :countings, class: 'Paleolog::Repo::Counting::Entity', key: :project_id
        many_to_many :samples, class: 'Paleolog::Repo::Sample::Entity', left_key: :project_id, right_key: :sample_id,
                               join_table: :sections
      end
    end
  end
end
