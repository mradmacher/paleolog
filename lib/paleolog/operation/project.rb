# frozen_string_literal: true

module Paleolog
  module Operation
    class Project
      class << self
        include Operation::Helpers

        CREATE_PARAMS_RULES = Pp.define.(
          name: Pp.required.(NameRules),
          user_id: Pp.required.(IdRules),
        )

        UPDATE_PARAMS_RULES = Pp.define.(
          id: Pp.required.(IdRules),
          name: Pp.required.(NameRules),
        )

        def find_all_for_user(user_id, authorizer:)
          perform(
            {},
            authenticate(authorizer),
            finalize(->(_) { Repo::Researcher.all_for_user(user_id).map(&:project) }),
          )
        end

        def create(raw_params, authorizer:)
          perform(
            raw_params,
            authenticate(authorizer),
            parameterize(CREATE_PARAMS_RULES),
            verify(name_uniqueness),
            finalize(
              lambda do |params|
                project = nil
                Paleolog::Repo::Config.db.transaction do
                  project = Paleolog::Repo::Project.create(params.except(:user_id))
                  Paleolog::Repo::Researcher.create(
                    user_id: params[:user_id],
                    project_id: project.id,
                    manager: true,
                  )
                end
                project
              end
            ),
          )
        end

        def rename(raw_params, authorizer:)
          perform(
            raw_params,
            authenticate(authorizer),
            parameterize(UPDATE_PARAMS_RULES),
            authorize_can_manage(authorizer, Paleolog::Project, :id),
            verify(name_uniqueness),
            finalize(->(params) { Paleolog::Repo::Project.update(params[:id], params.except(:id)) }),
          )
        end

        private

        def name_uniqueness
          lambda do |params|
            break unless params.key?(:name)

            if Paleolog::Repo::Project.similar_name_exists?(
              params[:name],
              exclude_id: params[:id],
            )
              { name: :taken }
            end
          end
        end
      end
    end
  end
end
