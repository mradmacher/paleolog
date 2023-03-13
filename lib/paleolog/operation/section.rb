# frozen_string_literal: true

module Paleolog
  module Operation
    class Section
      class << self
        CreateAuthRules = Pp.define.(
          user_id: Pp.required.(IdRules),
          project_id: Pp.required.(IdRules),
        )
        UpdateAuthRules = Pp.define.(
          user_id: Pp.required.(IdRules),
          id: Pp.required.(IdRules),
        )
        CreateRules = Pp.define.(
          name: Pp.required.(NameRules),
          project_id: Pp.required.(IdRules),
        )
        UpdateRules = Pp.define.(
          id: Pp.required.(IdRules),
          name: Pp.required.(NameRules),
        )

        def create(params)
          auth_params, errors = CreateAuthRules.(params)
          return [false, errors] unless errors.empty?

          unless Paleolog::Repo::ResearchParticipation.can_manage_project?(
            auth_params[:user_id],
            auth_params[:project_id],
          )
            return [false, { general: UNAUTHORIZED }]
          end

          params, errors = CreateRules.(params)
          return [nil, errors] unless errors.empty?

          if Paleolog::Repo::Section.name_exists_within_project?(params[:name], params[:project_id])
            return [nil, { name: :taken }]
          end

          section = Paleolog::Repo::Section.create(params)
          [section, {}]
        end

        def rename(params)
          auth_params, errors = UpdateAuthRules.(params)
          return [false, errors] unless errors.empty?

          unless Paleolog::Repo::ResearchParticipation.can_manage_section?(
            auth_params[:user_id],
            auth_params[:id],
          )
            return [false, { general: UNAUTHORIZED }]
          end

          params, errors = UpdateRules.(params)
          return [nil, errors] unless errors.empty?

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
