# frozen_string_literal: true

module Paleolog
  module Repo
    class ResearchParticipation
      class << self
        include CommonQueries

        def can_view_project?(user_id, project_id)
          !ds.where(project_id: project_id, user_id: user_id).first.nil?
        end

        def can_manage_project?(user_id, project_id)
          !ds.where(project_id: project_id, user_id: user_id, manager: true).first.nil?
        end

        def all_for_project(project_id)
          ds.where(project_id: project_id).all.map do |result|
            Paleolog::ResearchParticipation.new(**result) do |participation|
              participation.user = Paleolog::Repo::User.find(participation.user_id)
            end
          end
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
end
