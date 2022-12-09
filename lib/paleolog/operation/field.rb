# frozen_string_literal: true

module Paleolog
  module Operation
    class Field
      class << self
        FieldRules = Pp.define.(
          name: Pp.required.(
            Pp.string.(Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]))
          ),
          group_id: Pp.required.(Pp.integer.(Pp.gt.(0)))
        )

        def create(name:, group_id:)
          params, errors = FieldRules.(name: name, group_id: group_id)
          return Failure.new(errors) unless errors.empty?

          if Paleolog::Repo::Field.name_exists?(params[:name])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Field.create(params))
        end
      end
    end
  end
end
