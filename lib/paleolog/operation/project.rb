# frozen_string_literal: true

module Paleolog
  module Operation
    class Project < BaseOperation
      include Operation::CommonValidations

      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        user_id: Params.required.(Params::IdRules),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.required.(Params::NameRules),
      )

      def find_all
        authenticate
          .and_then { carefully(_1, find_projects(authorizer.user_id)) }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params.merge(user_id: authorizer.user_id), CREATE_PARAMS) }
          .and_then { verify(_1, name_uniqueness(Paleolog::Project)) }
          .and_then { carefully(_1, create_project) }
      end

      def rename(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Project, :id)) }
          .and_then { verify(_1, name_uniqueness(Paleolog::Project)) }
          .and_then { carefully(_1, update_project) }
      end

      private

      def find_projects(user_id)
        lambda do |_|
          repo.for(Paleolog::Researcher).all_for_user(user_id).map(&:project)
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
    end
  end
end
