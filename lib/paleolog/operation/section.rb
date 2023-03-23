# frozen_string_literal: true

module Paleolog
  module Operation
    class Section
      class << self
        CreateRules = Pp.define.(
          name: Pp.required.(NameRules),
          project_id: Pp.required.(IdRules),
        )
        UpdateRules = Pp.define.(
          id: Pp.required.(IdRules),
          name: Pp.required.(NameRules),
        )

        def create(params, authorizer:)
          return UNAUTHENTICATED_RESULT unless authorizer.authenticated?

          params, errors = CreateRules.(params)
          return [nil, errors] unless errors.empty?

          return UNAUTHORIZED_RESULT unless authorizer.can_manage?(Paleolog::Project, params[:project_id])

          if Paleolog::Repo::Section.name_exists_within_project?(params[:name], params[:project_id])
            return [nil, { name: :taken }]
          end

          section = Paleolog::Repo::Section.create(params)
          [section, {}]
        end

        def update(params, authorizer:)
          return UNAUTHENTICATED_RESULT unless authorizer.authenticated?

          params, errors = UpdateRules.(params)
          return [false, errors] unless errors.empty?

          return UNAUTHORIZED_RESULT unless authorizer.can_manage?(Paleolog::Section, params[:id])

          if Paleolog::Repo::Section.name_exists_within_same_project?(params[:name], section_id: params[:id])
            return [nil, { name: :taken }]
          end

          section = Paleolog::Repo::Section.update(params[:id], params.except(:id))
          [section, {}]
        end
      end
    end
  end
end
