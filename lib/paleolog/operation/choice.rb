# frozen_string_literal: true

module Paleolog
  module Operation
    class Choice
      class << self
        ChoiceRules = Pp.define.(
          name: Pp.required.(
            Pp.string.(Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]))
          ),
          field_id: Pp.required.(Pp.integer.(Pp.gt.(0))),
        )

        def create(name:, field_id:)
          params, errors = ChoiceRules.(name: name, field_id: field_id)
          return Failure.new(errors) unless errors.empty?

          if Paleolog::Repo::Choice.name_exists_within_field?(params[:name], params[:field_id])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Choice.create(params))
        end
      end
    end
  end
end
