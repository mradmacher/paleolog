# frozen_string_literal: true

module Paleolog
  module Operation
    class Project
      class << self
        CreateRules = Pp.define.(
          name: Pp.required.(NameRules),
          user_id: Pp.required.(IdRules),
        )
        UpdateRules = Pp.define.(
          id: Pp.required.(IdRules),
          name: Pp.required.(NameRules),
        )

        def find_all_for_user(user_id, authorizer:)
          return UNAUTHENTICATED_RESULT unless authorizer.authenticated?

          projects = Repo::Researcher.all_for_user(user_id).map(&:project)
          [projects, {}]
        end

        def create(params, authorizer:)
          return UNAUTHENTICATED_RESULT unless authorizer.authenticated?

          params, errors = CreateRules.(params)
          return [nil, errors] unless errors.empty?

          return [nil, { name: :taken }] if Paleolog::Repo::Project.name_exists?(params[:name])

          # FIXME: add transaction
          project = Paleolog::Repo::Project.create(name: params[:name])
          Paleolog::Repo::Researcher.create(
            user_id: params[:user_id],
            project_id: project.id,
            manager: true,
          )
          [project, {}]
        end

        def rename(params, authorizer:)
          return UNAUTHENTICATED_RESULT unless authorizer.authenticated?

          params, errors = UpdateRules.(params)
          return [nil, errors] unless errors.empty?

          return UNAUTHORIZED_RESULT unless authorizer.can_manage?(Paleolog::Project, params[:id])

          return [nil, { name: :taken }] if Paleolog::Repo::Project.name_exists?(params[:name], exclude_id: params[:id])

          project = Paleolog::Repo::Project.update(params[:id], params.except(:id))
          [project, {}]
        end
      end
    end
  end
end
