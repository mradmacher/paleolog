# frozen_string_literal: true

module Paleolog
  module Operation
    class Project
      class << self
        ProjectRules = Pp.define.(
          name: Pp.required.(Pp.string.(
            Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)])
          )),
        )

        def create(name:)
          params, errors = ProjectRules.(name: name)
          return Failure.new(errors) unless errors.empty?

          if Paleolog::Repo::Project.name_exists?(params[:name])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Project.create(params))
        end
      end
    end
  end
end
