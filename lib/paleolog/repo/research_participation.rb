# frozen_string_literal: true

module Paleolog
  module Repo
    class ResearchParticipation
      include CommonQueries

      def all_for_project(project_id)
        ds.where(project_id: project_id).all.map { |result|
          Paleolog::ResearchParticipation.new(**result) do |participation|
            participation.user = Paleolog::Repo::User.new.find(participation.user_id)
          end
        }
      end

      def entity_class
        Paleolog::ResearchParticipation
      end

      def ds
        Config.db[:research_participations]
      end
    end
  end
end

