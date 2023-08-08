# frozen_string_literal: true

module Paleolog
  module Operation
    class Species
      class << self
        include Operation::Helpers

        CREATE_PARAMS_RULES = Pp.define.(
          name: Pp.required.(Pp.string.(Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]))),
          group_id: Pp.required.(Pp.integer.(Pp.gt.(0))),
          description: Pp.optional.(DescriptionRules),
          environmental_preferences: Pp.optional.(DescriptionRules),
        )

        def create(raw_params, authorizer:)
          result = perform(
            raw_params,
            authenticate(authorizer),
            parameterize(CREATE_PARAMS_RULES),
            verify(name_uniqueness),
            finalize(
              lambda do |params|
                Paleolog::Repo::Species.create(params)
              end
            )
          )
          if result.last.empty?
            Success.new(result.first)
          else
            Failure.new(result.last)
          end
        end

        private

        def name_uniqueness
          lambda do |params|
            break unless params.key?(:name)

            if Paleolog::Repo::Species.name_exists_within_group?(
              params[:name],
              params[:group_id],
              exclude_id: params[:id],
            )
              { name: :taken }
            end
          end
        end
      end
    end
  end
end
