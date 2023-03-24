# frozen_string_literal: true

module Paleolog
  module Repo
    class Researcher
      class << self
        include CommonQueries

        def can_view_project?(user_id, project_id)
          !ds.where(project_id: project_id, user_id: user_id).first.nil?
        end

        def can_manage_project?(user_id, project_id)
          !ds.where(project_id: project_id, user_id: user_id, manager: true).first.nil?
        end

        def can_manage_section?(user_id, section_id)
          !ds.where(user_id: user_id, manager: true, Sequel[:sections][:id] => section_id)
             .join(:projects, Sequel[:projects][:id] => :project_id)
             .join(:sections, Sequel[:sections][:project_id] => :id).first.nil?
        end

        def can_manage_counting?(user_id, counting_id)
          !ds.where(user_id: user_id, manager: true, Sequel[:countings][:id] => counting_id)
             .join(:projects, Sequel[:projects][:id] => :project_id)
             .join(:countings, Sequel[:countings][:project_id] => :id).first.nil?
        end

        def all_for_user(user_id)
          ds.where(user_id: user_id).all.map do |result|
            Paleolog::Researcher.new(**result) do |participation|
              participation.project = Paleolog::Repo::Project.find(participation.project_id)
            end
          end
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
      end
    end
  end
end
