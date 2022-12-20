# frozen_string_literal: true

module Paleolog
  module Operation
    class Sample
      class << self
        CreateParams = Pp.define.(
          name: Pp.required.(Pp.string.(Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]))),
          section_id: Pp.required.(Pp.integer.(Pp.gt.(0))),
          weight: Pp.optional.(Pp.decimal.(Pp.gt.(0.0))),
        )

        UpdateParams = Pp.define.(
          rank: Pp.optional.(Pp.integer.(Pp.any)),
        )

        def create(name:, section_id:, weight: Option.None)
          params, errors = CreateParams.(name: name, section_id: section_id, weight: weight)
          return Failure.new(errors) unless errors.empty?

          if Paleolog::Repo::Sample.name_exists_within_section?(params[:name], params[:section_id])
            return Failure.new({ name: :taken })
          end

          max_rank = Paleolog::Repo::Sample
            .all_for_section(section_id)
            .max_by(&:rank)&.rank || 0
          params[:rank] = max_rank + 1

          Success.new(Paleolog::Repo::Sample.create(params))
        end
      end
    end
  end
end
