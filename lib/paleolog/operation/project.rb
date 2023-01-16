# frozen_string_literal: true

module Paleolog
  module Operation
    class Project
      class << self
        NameRules = Pp.required.(
          Pp.string.(
            Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]),
          ),
        )
        CreateRules = Pp.define.(
          name: NameRules,
          user_id: Pp.required.(Pp.integer.(Pp.gt.(0))),
        )
        UpdateRules = Pp.define.(
          name: NameRules,
        )

        def find_all_for_user(user_id)
          Repo::ResearchParticipation.all_for_user(user_id).map(&:project)
        end

        def create(name:, user_id:)
          params, errors = CreateRules.(name: name, user_id: user_id)
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

        def rename(project_id, name:)
          params, errors = UpdateRules.(name: name)
          return [nil, errors] unless errors.empty?

          return [nil, { name: :taken }] if Paleolog::Repo::Project.name_exists?(params[:name], exclude_id: project_id)

          project = Paleolog::Repo::Project.update(project_id, params)
          [project, {}]
        end
      end
    end
  end
end
