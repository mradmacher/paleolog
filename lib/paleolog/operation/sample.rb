# frozen_string_literal: true

module Paleolog
  module Operation
    class Sample < BaseOperation
      CREATE_PARAMS_RULES = Pp.define.(
        name: Pp.required.(NameRules),
        section_id: Pp.required.(IdRules),
        description: Pp.optional.(DescriptionRules),
        weight: Pp.optional.(Pp.blank_to_nil_or.(Pp.decimal.(Pp.gt.(0.0)))),
      )

      UPDATE_PARAMS_RULES = Pp.define.(
        id: Pp.required.(IdRules),
        name: Pp.optional.(NameRules),
        description: Pp.optional.(DescriptionRules),
        weight: Pp.optional.(Pp.blank_to_nil_or.(Pp.decimal.(Pp.gt.(0.0)))),
      )

      def create(raw_params)
        reduce(
          raw_params,
          authenticate(authorizer),
          parameterize(CREATE_PARAMS_RULES),
          authorize_can_manage(authorizer, Paleolog::Section, :section_id),
          verify(name_uniqueness),
          merge(next_rank),
          finalize(->(params) { repo.for(Paleolog::Sample).create(params) }),
        )
      end

      def update(raw_params)
        reduce(
          raw_params,
          authenticate(authorizer),
          parameterize(UPDATE_PARAMS_RULES),
          authorize_can_manage(authorizer, Paleolog::Sample, :id),
          verify(name_uniqueness),
          finalize(->(params) { repo.for(Paleolog::Sample).update(params[:id], params.except(:id)) }),
        )
      end

      private

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          if repo.for(Paleolog::Sample).similar_name_exists?(
            params[:name],
            section_id: params[:section_id],
            exclude_id: params[:id],
          )
            { name: TAKEN }
          end
        end
      end

      def next_rank
        lambda do |params|
          max_rank = repo.for(Paleolog::Sample).section_max_rank(params[:section_id]) || 0
          { rank: max_rank + 1 }
        end
      end
    end
  end
end
