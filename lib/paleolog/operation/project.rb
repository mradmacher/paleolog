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
          return Failure.new(errors) unless errors.empty?

          return Failure.new({ name: :taken }) if Paleolog::Repo::Project.name_exists?(params[:name])

          Success.new(Paleolog::Repo::Project.create(params)).tap do |result|
            Paleolog::Repo::ResearchParticipation.create(
              user_id: user_id,
              project_id: result.value.id,
              manager: true,
            )
          end
        end
      end
    end
  end
end
