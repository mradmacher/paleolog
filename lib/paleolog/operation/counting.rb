# frozen_string_literal: true

module Paleolog
  module Operation
    class Counting
      class << self
        include Operation::Helpers

        CREATE_PARAMS_RULES = Pp.define.(
          name: Pp.required.(NameRules),
          project_id: Pp.required.(IdRules),
        )

        UPDATE_PARAMS_RULES = Pp.define.(
          id: Pp.required.(IdRules),
          name: Pp.required.(NameRules),
        )

        def create(raw_params, authorizer:)
          reduce(
            raw_params,
            authenticate(authorizer),
            parameterize(CREATE_PARAMS_RULES),
            authorize_can_manage(authorizer, Paleolog::Project, :project_id),
            verify(name_uniqueness),
            finalize(->(params) { Paleolog::Repo::Counting.create(params) }),
          )
        end

        def update(raw_params, authorizer:)
          reduce(
            raw_params,
            authenticate(authorizer),
            parameterize(UPDATE_PARAMS_RULES),
            authorize_can_manage(authorizer, Paleolog::Counting, :id),
            verify(name_uniqueness),
            finalize(->(params) { Paleolog::Repo::Counting.update(params[:id], params.except(:id)) }),
          )
        end

        private

        def name_uniqueness
          lambda do |params|
            break unless params.key?(:name)

            if Paleolog::Repo::Counting.similar_name_exists?(
              params[:name],
              project_id: params[:project_id],
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
