# frozen_string_literal: true

module Paleolog
  module Operation
    class Sample
      class << self
        CreateParams = Pp.define.(
          name: Pp.required.(NameRules),
          section_id: Pp.required.(IdRules),
          weight: Pp.optional.(Pp.decimal.(Pp.gt.(0.0))),
        )

        UpdateParams = Pp.define.(
          id: Pp.required.(IdRules),
          rank: Pp.optional.(Pp.integer.(Pp.any)),
        )

        def create(params, authorizer:)
          return UNAUTHENTICATED_RESULT unless authorizer.authenticated?

          params, errors = CreateParams.(params)
          return [nil, errors] unless errors.empty?

          return UNAUTHORIZED_RESULT unless authorizer.can_manage?(Paleolog::Section, params[:section_id])

          if Paleolog::Repo::Sample.name_exists_within_section?(params[:name], params[:section_id])
            return [nil, { name: TAKEN }]
          end

          max_rank = Paleolog::Repo::Sample
                     .all_for_section(params[:section_id])
                     .max_by(&:rank)&.rank || 0

          sample = Paleolog::Repo::Sample.create(params.merge(rank: max_rank + 1))
          [sample, {}]
        end
      end
    end
  end
end
