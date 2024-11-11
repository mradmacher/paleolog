# frozen_string_literal: true

module Paleolog
  module Repo
    class Species
      class << self
        include CommonQueries

        # rubocop:disable Metrics/AbcSize
        def find(id)
          result = ds.where(id: id).first
          return nil unless result

          Paleolog::Species.new(**result) do |species|
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

          groups = Paleolog::Repo::Group.all
          query.all.map do |result|
            Paleolog::Species.new(**result) do |species|
              species.group = groups.detect { |group| group.id == species.group_id }
            end
          end
        end

        def name_exists?(name, group_id: nil, exclude_id: nil)
          scope =
            if group_id
              ds.where(group_id: group_id)
            elsif exclude_id
              ds.where(group_id: ds.where(id: exclude_id).select(:group_id))
            else
              ds
            end
          query = exclude_id ? scope.exclude(id: exclude_id) : scope
          query.where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
        end

        def entity_class
          Paleolog::Species
        end

        def ds
          Config.db[:species]
        end

        private

        def project_filter(query, project_id)
          occurrences_refs =
            Config.db[:occurrences]
                  .where(Sequel[:sections][:project_id] => project_id)
                  .join(:samples, Sequel[:samples][:id] => :sample_id)
                  .join(:sections, Sequel[:sections][:id] => :section_id)
          query.where(id: occurrences_refs.select(:species_id))
        end

        def search_query(filters = {})
          query = ds
          query = query.where(group_id: filters[:group_id]) if filters[:group_id]
          query = query.where(Sequel.ilike(Sequel[:species][:name], "%#{filters[:name]}%")) if filters[:name]
          query = query.where(verified: true) if filters[:verified]
          query = project_filter(query, filters[:project_id]) if filters[:project_id]
          query
        end
      end
    end
  end
end
