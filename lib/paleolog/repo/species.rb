# frozen_string_literal: true

module Paleolog
  module Repo
    class Species
      class << self
        include CommonQueries

        # rubocop:disable Metrics/AbcSize
        def find(id)
          Paleolog::Species.new(**ds.where(id: id).first) do |species|
            species.group = Paleolog::Repo::Group.find(species.group_id)
            Paleolog::Repo::Feature.all_for_species(species.id).each do |feature|
              species.features << feature
            end
            Paleolog::Repo::Image.all_for_species(species.id).each do |image|
              species.images << image
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        def all_with_ids(species_ids)
          groups = Paleolog::Repo::Group.all
          ds.where(id: species_ids).all.map do |result|
            Paleolog::Species.new(**result) do |species|
              species.group = groups.detect { |group| group.id == species.group_id }
              Paleolog::Repo::Feature.all_for_species(species.id).each do |feature|
                species.features << feature
              end
            end
          end
        end

        def all_for_group(group_id)
          ds.where(group_id: group_id).all.map do |result|
            Paleolog::Species.new(**result)
          end
        end

        def search(filters = {})
          groups = Paleolog::Repo::Group.all
          search_query(filters).all.map do |result|
            Paleolog::Species.new(**result) do |species|
              species.group = groups.detect { |group| group.id == species.group_id }
            end
          end
        end

        def search_in_project(_project, filters = {})
          query = search_query(filters)

          # @project = Project.find(params[:project_id])
          # @project_id = @project.id
          # occurrence_specimen_ids =
          #   Occurrence.joins(:counting).where('countings.project_id' => @project_id)
          #   .select(:specimen_id).distinct.map(&:specimen_id)
          # image_specimen_ids = Image.joins(sample: :section).where('sections.project_id' => @project_id)
          #   .select(:specimen_id).distinct.map(&:specimen_id)
          # specimen_ids = occurrence_specimen_ids + image_specimen_ids
          # @specimens = @specimens.where(id: specimen_ids)
          groups = Paleolog::Repo::Group.all
          query.all.map do |result|
            Paleolog::Species.new(**result) do |species|
              species.group = groups.detect { |group| group.id == species.group_id }
            end
          end
        end

        def name_exists_within_group?(name, group_id)
          ds.where(group_id: group_id).where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
        end

        def entity_class
          Paleolog::Species
        end

        def ds
          Config.db[:species]
        end

        private

        def search_query(filters = {})
          query = ds
          query = query.where(group_id: filters[:group_id]) if filters[:group_id]
          query = query.where(Sequel.ilike(Sequel[:species][:name], "%#{filters[:name]}%")) if filters[:name]
          query = query.where(verified: true) if filters[:verified]
          if filters[:project_id]
            query = query
              .where(Sequel[:sections][:project_id] => filters[:project_id])
              .join(:occurrences, Sequel[:occurrences][:species_id] => :id)
              .join(:samples, Sequel[:samples][:id] => :sample_id)
              .join(:sections, Sequel[:sections][:id] => :section_id)
              .select_all(:species)
              .union(
                ds.where(Sequel[:sections][:project_id] => filters[:project_id])
                  .join(:images, Sequel[:images][:species_id] => :id)
                  .join(:samples, Sequel[:samples][:id] => :sample_id)
                  .join(:sections, Sequel[:sections][:id] => :section_id)
                  .select_all(:species)
              )
          end
          query
        end
      end
    end
  end
end
