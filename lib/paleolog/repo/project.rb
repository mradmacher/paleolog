# frozen_string_literal: true

module Paleolog
  module Repo
    class Project
      include CommonQueries

      def find(id)
        Paleolog::Project.new(**ds.where(id: id).first) do |project|
          Paleolog::Repo::Counting.new.all_for_project(project.id).each do |counting|
            project.countings << counting
          end
          Paleolog::Repo::Section.new.all_for_project(project.id).each do |section|
            project.sections << section
          end
          Paleolog::Repo::ResearchParticipation.new.all_for_project(project.id).each do |participation|
            project.research_participations << participation
          end
        end
      end

      def name_exists?(name)
        ds.where(Sequel.ilike(:name, name.upcase)).limit(1).count > 0
      end

      def entity_class
        Paleolog::Project
      end

      def ds
        Config.db[:projects]
      end
    end
  end
end
