# frozen_string_literal: true

module Paleolog
  module Operation
    class Section
      class << self
        SectionParams = Pp.define.(
          name: Pp.required.(Pp.string.(Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]))),
          project_id: Pp.required.(Pp.integer.(Pp.gt.(0))),
        )

        def create(name:, project_id:)
          params, errors = SectionParams.(name: name, project_id: project_id)
          return Failure.new(errors) unless errors.empty?

          if Paleolog::Repo::Section.name_exists_within_project?(params[:name], params[:project_id])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Section.create(params))
        end
      end
    end
  end
end
