# frozen_string_literal: true

require 'rom-repository'
require 'rom-changeset'

module Paleolog
  module Repository
    class Species < ROM::Repository[:species]
      commands update: :by_pk, delete: :by_pk

      def self.new(container = Paleolog::Repository::Config.db)
        super(container)
      end

      def find(id)
        species.combine(:group).by_pk(id).one!
      end

      def find_with_dependencies(id)
        species.combine(:group).combine(choices: [:fields]).combine(:images).by_pk(id).one!
      end

      def in_group(group)
        species.where(group_id: group.id).to_a
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

      def search(filters = {})
        query = species.combine(:group)
        query = query.where(group_id: filters[:group_id]) if filters[:group_id]
        query = query.where { name.ilike("%#{filters[:name]}%") } if filters[:name]
        query
      end

      def search_verified(filters = {})
        query = search(filters).where(verified: true)
        query.to_a
      end

      def search_in_project(project, filters = {})
        query = search(filters)

        #@project = Project.find(params[:project_id])
        #@project_id = @project.id
        #occurrence_specimen_ids = Occurrence.joins(:counting).where('countings.project_id' => @project_id).select(:specimen_id).distinct.map(&:specimen_id)
        #image_specimen_ids = Image.joins(sample: :section).where('sections.project_id' => @project_id).select(:specimen_id).distinct.map(&:specimen_id)
        #specimen_ids = occurrence_specimen_ids + image_specimen_ids
        #@specimens = @specimens.where(id: specimen_ids)
        query.to_a
      end
    end
  end
end
