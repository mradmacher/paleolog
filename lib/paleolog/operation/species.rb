# frozen_string_literal: true

module Paleolog
  module Operation
    class Species
      class << self
        Params = Pp.define.(
          name: Pp.required.(Pp.string.(Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]))),
          group_id: Pp.required.(Pp.integer.(Pp.gt.(0))),
          description: Pp.optional.(Pp.blank_to_nil_or.(Pp.string.(Pp.max_size.(4096)))),
          environmental_preferences: Pp.optional.(Pp.blank_to_nil_or.(Pp.string.(Pp.max_size.(4096)))),
        )

        def create(name:, group_id:, description: Option.None, environmental_preferences: Option.None)
          params, errors = Params.(
            name: name,
            group_id: group_id,
            description: description,
            environmental_preferences: environmental_preferences,
          )
          return Failure.new(errors) unless errors.empty?

          if Paleolog::Repo::Species.name_exists_within_group?(params[:name], params[:group_id])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Species.create(params))
        end
      end
    end
  end
end
