# frozen_string_literal: true

module Paleolog
  module Repo
    class Counting
      class << self
        include CommonQueries

        def all_for_project(project_id)
          ds.where(project_id: project_id).all.map do |result|
            Paleolog::Counting.new(**result)
          end
        end

        def find(id)
          result = ds.where(id: id).first
          return nil unless result

          Paleolog::Counting.new(**result) do |counting|
            counting.group = Paleolog::Repo::Group.find(counting.group_id) unless counting.group_id.nil?
            counting.marker = Paleolog::Repo::Species.find(counting.marker_id) unless counting.marker_id.nil?
          end
        end

        def find_for_project(id, project_id)
          result = ds.where(project_id: project_id, id: id).first
          return nil unless result

          Paleolog::Counting.new(**result) do |counting|
            counting.group = Paleolog::Repo::Group.find(counting.group_id) unless counting.group_id.nil?
            counting.marker = Paleolog::Repo::Species.find(counting.marker_id) unless counting.marker_id.nil?
          end
        end

        def similar_name_exists?(name, project_id: nil, exclude_id: nil)
          scope =
            if project_id
              ds.where(project_id: project_id)
            elsif exclude_id
              ds.where(project_id: ds.where(id: exclude_id).select(:project_id))
            else
              ds
            end
          query = exclude_id ? scope.exclude(id: exclude_id) : scope
          query.where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
        end

        def entity_class
          Paleolog::Counting
        end

        def ds
          Config.db[:countings]
        end

        def use_timestamps?
          false
        end
      end
    end
  end
end
