# frozen_string_literal: true

module Paleolog
  module Operation
    class Sample
      class << self
        CreateParams = Pp.define.(
          name: Pp.required.(NameRules),
          section_id: Pp.required.(IdRules),
          description: Pp.optional.(DescriptionRules),
          weight: Pp.optional.(Pp.decimal.(Pp.gt.(0.0))),
        )

        UpdateParams = Pp.define.(
          id: Pp.required.(IdRules),
          name: Pp.optional.(NameRules),
          description: Pp.optional.(DescriptionRules),
          weight: Pp.optional.(Pp.blank_to_nil_or.(Pp.decimal.(Pp.gt.(0.0)))),
        )

        def create(params, authorizer:)
          return UNAUTHENTICATED_RESULT unless authorizer.authenticated?

          params, errors = CreateParams.(params)
          return [nil, errors] unless errors.empty?

          return UNAUTHORIZED_RESULT unless authorizer.can_manage?(Paleolog::Section, params[:section_id])

          if Paleolog::Repo::Sample.name_exists_within_section?(params[:name], params[:section_id])
            return [nil, { name: TAKEN }]
          end

          max_rank = Paleolog::Repo::Sample.section_max_rank(params[:section_id]) || 0

          sample = Paleolog::Repo::Sample.create(params.merge(rank: max_rank + 1))
          [sample, {}]
        end

        def update(params, authorizer:)
          return UNAUTHENTICATED_RESULT unless authorizer.authenticated?

          params, errors = UpdateParams.(params)
          return [nil, errors] unless errors.empty?

          return UNAUTHORIZED_RESULT unless authorizer.can_manage?(Paleolog::Sample, params[:id])

          if params.key?(:name) &&
             Paleolog::Repo::Sample.name_exists_within_same_section?(params[:name], sample_id: params[:id])

            return [nil, { name: TAKEN }]
          end

          sample = Paleolog::Repo::Sample.update(params[:id], params.except(:id))
          [sample, {}]
        end
      end
    end
  end
end
