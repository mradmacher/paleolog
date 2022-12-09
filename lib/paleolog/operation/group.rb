# frozen_string_literal: true

module Paleolog
  module Operation
    class Group
      class << self
        GroupRules = Pp.define.(
          name: Pp.required.(
            Pp.string.(Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]))
          ),
        )

        def create(name:)
          params, errors = GroupRules.(name: name)
          return Failure.new(errors) unless errors.empty?

          if Paleolog::Repo::Group.name_exists?(params[:name])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Group.create(params))
        end
      end
    end
  end
end
