# frozen_string_literal: true

module Paleolog
  module Repo
    class Researcher
      NONE = :none
      MANAGER = :manager
      OBSERVER = :observer

      class << self
        include CommonQueries

        def project_role(project_id, user_id)
          role_for(
            ds.where(project_id: project_id, user_id: user_id).select_map(:manager),
          )
        end

        def section_role(section_id, user_id)
          role_for(
            ds.where(user_id: user_id, Sequel[:sections][:id] => section_id)
              .join(:projects, Sequel[:projects][:id] => :project_id)
              .join(:sections, Sequel[:sections][:project_id] => :id).select_map(:manager),
          )
        end

        def sample_role(sample_id, user_id)
          role_for(
            ds.where(user_id: user_id, Sequel[:samples][:id] => sample_id)
              .join(:projects, Sequel[:projects][:id] => :project_id)
              .join(:sections, Sequel[:sections][:project_id] => :id)
              .join(:samples, Sequel[:samples][:section_id] => :id).select_map(:manager),
          )
        end

        def counting_role(counting_id, user_id)
          role_for(
            ds.where(user_id: user_id, Sequel[:countings][:id] => counting_id)
               .join(:projects, Sequel[:projects][:id] => :project_id)
               .join(:countings, Sequel[:countings][:project_id] => :id).select_map(:manager),
          )
        end

        def find_for_project_and_user(project_id, user_id)
          result = ds.where(user_id: user_id, project_id: project_id).first
          return nil unless result

          Paleolog::Researcher.new(**result)
        end

        def all_for_project(project_id)
          ds.where(project_id: project_id).all.map do |result|
            Paleolog::Researcher.new(**result) do |participation|
              participation.user = Paleolog::Repo::User.find(participation.user_id)
            end
          end
        end

        def entity_class
          Paleolog::Researcher
        end

        def ds
          Config.db[:research_participations]
        end

        private

        def role_for(booleans)
          return NONE if booleans.empty?

          booleans.any? ? MANAGER : OBSERVER
        end
      end
    end
  end
end
