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

        def find_all_for_user(user_id)
          Repo::ResearchParticipation.all_for_user(user_id).map(&:project)
        end

        def create(params, user_id:)
          return UNAUTHORIZED_RESULT if user_id.nil?

          params, errors = CreateRules.(params.merge(user_id: user_id))
          return [nil, errors] unless errors.empty?

          return [nil, { name: :taken }] if Paleolog::Repo::Project.name_exists?(params[:name])

          # FIXME: add transaction
          project = Paleolog::Repo::Project.create(name: params[:name])
          Paleolog::Repo::ResearchParticipation.create(
            user_id: params[:user_id],
            project_id: project.id,
            manager: true,
          )
          [project, {}]
        end

        def rename(params, user_id:)
          return UNAUTHORIZED_RESULT if user_id.nil?

          params, errors = UpdateRules.(params)
          return [nil, errors] unless errors.empty?

          unless Paleolog::Repo::ResearchParticipation.can_manage_project?(
            user_id,
            params[:id],
          )
            return UNAUTHORIZED_RESULT
          end

          return [nil, { name: :taken }] if Paleolog::Repo::Project.name_exists?(params[:name], exclude_id: params[:id])

          project = Paleolog::Repo::Project.update(params[:id], params.except(:id))
          [project, {}]
        end
      end
    end
  end
end
