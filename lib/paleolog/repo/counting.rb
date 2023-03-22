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

        def find_for_project(id, project_id)
          result = ds.where(project_id: project_id, id: id).first
          return nil unless result

          Paleolog::Counting.new(**result) do |counting|
            counting.group = Paleolog::Repo::Group.find(counting.group_id) unless counting.group_id.nil?
            counting.marker = Paleolog::Repo::Species.find(counting.marker_id) unless counting.marker_id.nil?
          end
        end

        def name_exists_within_project?(name, project_id)
          ds.where(project_id: project_id).where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
        end

        def name_exists_within_same_project?(name, counting_id:)
          ds.exclude(id: counting_id)
            .where(project_id: ds.where(id: counting_id).select(:project_id))
            .where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
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
