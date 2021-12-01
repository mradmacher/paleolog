# frozen_string_literal: true

module Paleolog
  module Repo
    class Counting
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
          counting.group = Paleolog::Repo::Group.new.find(counting.group_id) unless counting.group_id.nil?
          counting.marker = Paleolog::Repo::Species.new.find(counting.marker_id) unless counting.marker_id.nil?
        end
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
