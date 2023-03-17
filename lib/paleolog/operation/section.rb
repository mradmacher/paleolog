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

        def create(params, user_id:)
          return [nil, { general: UNAUTHORIZED }] if user_id.nil?

          params, errors = CreateRules.(params)
          return [nil, errors] unless errors.empty?

          unless Paleolog::Repo::ResearchParticipation.can_manage_project?(
            user_id,
            params[:project_id],
          )
            return [false, { general: UNAUTHORIZED }]
          end

          if Paleolog::Repo::Section.name_exists_within_project?(params[:name], params[:project_id])
            return [nil, { name: :taken }]
          end

          section = Paleolog::Repo::Section.create(params)
          [section, {}]
        end

        def rename(params, user_id:)
          return [nil, { general: UNAUTHORIZED }] if user_id.nil?

          params, errors = UpdateRules.(params)
          return [false, errors] unless errors.empty?

          unless Paleolog::Repo::ResearchParticipation.can_manage_section?(
            user_id,
            params[:id],
          )
            return [false, { general: UNAUTHORIZED }]
          end

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
