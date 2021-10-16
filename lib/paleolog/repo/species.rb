# frozen_string_literal: true

module Paleolog
  module Repo
    class Species
      def find_by_id(id)
        Entity[id]
      end

      def update(id, attributes)
        Entity.where(id: id).update(attributes)
      end

      def in_group(group)
        Entity.where(group_id: group.id).to_a
      end

      def delete_all
        Entity.dataset.delete
      end

      def add_feature(species, choice)
        Feature::Entity.create(choice_id: choice.id, species_id: species.id)
      end

      def add_image(species, attributes)
        Image::Entity.create(attributes.merge(species_id: species.id))
      end

      def search(filters = {})
        query = Species::Entity
        query = query.where(group_id: filters[:group_id]) if filters[:group_id]
        query = query.where { name.ilike("%#{filters[:name]}%") } if filters[:name]
        query
      end

      def search_verified(filters = {})
        query = search(filters).where(verified: true)
        query.to_a
      end

      def search_in_project(_project, filters = {})
        query = search(filters)

        # @project = Project.find(params[:project_id])
        # @project_id = @project.id
        # occurrence_specimen_ids = Occurrence.joins(:counting).where('countings.project_id' => @project_id).select(:specimen_id).distinct.map(&:specimen_id)
        # image_specimen_ids = Image.joins(sample: :section).where('sections.project_id' => @project_id).select(:specimen_id).distinct.map(&:specimen_id)
        # specimen_ids = occurrence_specimen_ids + image_specimen_ids
        # @specimens = @specimens.where(id: specimen_ids)
        query.to_a
      end

      class Entity < Sequel::Model(Config.db[:species])
        many_to_one :group, class: 'Paleolog::Repo::Group::Entity'
        one_to_many :features, class: 'Paleolog::Repo::Feature::Entity', key: :species_id
        one_to_many :images, class: 'Paleolog::Repo::Image::Entity', key: :species_id
        many_to_many :choices, class: 'Paleolog::Repo::Choice::Entity', left_key: :species_id, right_key: :choice_id,
                               join_table: :features
      end
    end
  end
end
