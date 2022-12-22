# frozen_string_literal: true

module Paleolog
  module Operation
    class Project
      class << self
        ProjectRules = Pp.define.(
          name: Pp.required.(
            Pp.string.(
              Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]),
            )
          ),
        )

        def find_all_for_user(user_id)
          Repo::ResearchParticipation.all_for_user(user_id).map(&:project)
        end

        def create(name:, user_id:)
          params, errors = ProjectRules.(name: name)
          return [nil, errors] unless errors.empty?

          return [nil, { name: :taken }] if Paleolog::Repo::Project.name_exists?(params[:name])

          # FIXME: add transaction
          project = Paleolog::Repo::Project.create(params)
          Paleolog::Repo::ResearchParticipation.create(
            user_id: user_id,
            project_id: project.id,
            manager: true,
          )
          [project, {}]
        end
      end
    end
  end
end
