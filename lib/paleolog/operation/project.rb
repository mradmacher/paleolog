# frozen_string_literal: true

module Paleolog
  module Operation
    class Project < BaseOperation
      FIND_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules)
      )

      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        user_id: Params.required.(Params::IdRules),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.required.(Params::NameRules),
      )

      def find(raw_params)
        parameterize(raw_params, FIND_PARAMS)
          .and_then { carefully(_1, find_project) }
      end

      def find_all
        authenticate
          .and_then { carefully(_1, find_projects(authorizer.user_id)) }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params.merge(user_id: authorizer.user_id), CREATE_PARAMS) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, create_project) }
      end

      def rename(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Project, :id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, update_project) }
      end

      private

      def find_project
        lambda do  |params|
          result = repo.db[:projects].where(id: params[:id]).first
          return nil unless result

          Paleolog::Project.new(**result) do |project|
            Paleolog::Repo::Counting.all_for_project(project.id).each do |counting|
              project.countings << counting
            end
            Paleolog::Repo::Section.all_for_project(project.id).each do |section|
              project.sections << section
            end
            Paleolog::Repo::Researcher.all_for_project(project.id).each do |researcher|
              project.researchers << researcher
            end
          end
        end
      end

      def find_projects(user_id)
        lambda do |_|
          repo
            .db[:projects]
            .join(:research_participations, Sequel[:research_participations][:project_id] => :id)
            .where(user_id: user_id)
            .reverse_order(:created_at)
            .select_all(:projects)
            .map { Paleolog::Project.new(**_1) }
        end
      end

      def update_project
        lambda do |params|
          repo.find(
            Paleolog::Project,
            repo.save(Paleolog::Project.new(**params)),
          )
        end
      end

      def create_project
        lambda do |params|
          project_id = nil
          repo.with_transaction do
            project_id = repo.save(Paleolog::Project.new(**params.except(:user_id)))
            repo.save(
              Paleolog::Researcher.new(
                user_id: params[:user_id],
                project_id: project_id,
                manager: true,
              ),
            )
          end
          repo.find(Paleolog::Project, project_id)
        end
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          if repo.for(Paleolog::Project).similar_name_exists?(
            params[:name],
            exclude_id: params[:id],
          )
            { name: TAKEN }
          end
        end
      end
    end
  end
end
