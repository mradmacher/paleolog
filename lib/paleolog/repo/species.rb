# frozen_string_literal: true

module Paleolog
  module Repo
    class Species
      include CommonQueries

      def find(id)
        Paleolog::Species.new(**ds.where(id: id).first) { |species|
          species.group = Paleolog::Repo::Group.new.find(species.group_id)
          Paleolog::Repo::Feature.new.all_for_species(species.id).each do |feature|
            species.features << feature
          end
          Paleolog::Repo::Image.new.all_for_species(species.id).each do |image|
            species.images << image
          end
        }
      end

      def all_with_ids(species_ids)
        groups = Paleolog::Repo::Group.new.all
        ds.where(id: species_ids).all.map { |result|
          Paleolog::Species.new(**result) { |species|
            species.group = groups.detect { |group| group.id == species.group_id }
            Paleolog::Repo::Feature.new.all_for_species(species.id).each do |feature|
              species.features << feature
            end
          }
        }
      end

      def all_for_group(group_id)
        ds.where(group_id: group_id).all.map { |result|
          Paleolog::Species.new(**result)
        }
      end

      def search(filters = {})
        query = ds
        query = query.where(group_id: filters[:group_id]) if filters[:group_id]
        query = query.where { name.ilike("%#{filters[:name]}%") } if filters[:name]
        query
      end

      def search_verified(filters = {})
        groups = Paleolog::Repo::Group.new.all
        query = search(filters).where(verified: true)
        query.all.map { |result|
          Paleolog::Species.new(**result) { |species|
            species.group = groups.detect { |group| group.id == species.group_id }
          }
        }
      end

      def search_in_project(_project, filters = {})
        query = search(filters)

        # @project = Project.find(params[:project_id])
        # @project_id = @project.id
        # occurrence_specimen_ids = Occurrence.joins(:counting).where('countings.project_id' => @project_id).select(:specimen_id).distinct.map(&:specimen_id)
        # image_specimen_ids = Image.joins(sample: :section).where('sections.project_id' => @project_id).select(:specimen_id).distinct.map(&:specimen_id)
        # specimen_ids = occurrence_specimen_ids + image_specimen_ids
        # @specimens = @specimens.where(id: specimen_ids)
        query.all.map { |result| Paleolog::Species.new(**result) }
      end

      def name_exists_within_group?(name, group_id)
        ds.where(group_id: group_id).where(Sequel.ilike(:name, name.upcase)).limit(1).count > 0
      end

      def entity_class
        Paleolog::Species
      end

      def ds
        Config.db[:species]
      end
    end
  end
end
