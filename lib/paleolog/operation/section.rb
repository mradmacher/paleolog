# frozen_string_literal: true

module Paleolog
  module Operation
    class Section
      class << self
        NameRules = Pp.required.(
          Pp.string.(
            Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)])
          )
        )

        CreateRules = Pp.define.(
          name: NameRules,
          project_id: Pp.required.(Pp.integer.(Pp.gt.(0))),
        )
        UpdateRules = Pp.define.(
          name: NameRules,
        )

        def create(name:, project_id:)
          params, errors = CreateRules.(name: name, project_id: project_id)
          return [nil, errors] unless errors.empty?

          if Paleolog::Repo::Section.name_exists_within_project?(params[:name], params[:project_id])
            return [nil, { name: :taken }]
          end

          section = Paleolog::Repo::Section.create(params)
          [section, {}]
        end

        def rename(section_id, name:)
          params, errors = UpdateRules.(name: name)
          return [nil, errors] unless errors.empty?

          return [nil, { name: :taken }] if Paleolog::Repo::Section.name_exists_within_same_project?(params[:name], section_id: section_id)

          section = Paleolog::Repo::Section.update(section_id, params)
          [section, {}]
        end
      end
    end
  end
end
