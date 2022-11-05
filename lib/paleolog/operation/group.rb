# frozen_string_literal: true

require 'paleolog/utils'

module Paleolog
  module Operation
    class Group
      class << self
        include Validations

        GroupParams = Validate.(
          name: Required.(IsString.(AnyOf.([Stripped, NotBlank, MaxSize.(255)])))
        )

        def create(name:)
          result = GroupParams.(name: name)
          return result if result.failure?

          if Paleolog::Repo::Group.name_exists?(result.value[:name])
            return Failure.new({ name: :taken })
          end

          Success.new(Paleolog::Repo::Group.create(result.value))
        end
      end
    end
  end
end
