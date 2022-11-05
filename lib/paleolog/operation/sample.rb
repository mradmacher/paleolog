# frozen_string_literal: true

require 'paleolog/utils'

module Paleolog
  module Operation
    class Sample
      class << self
        include Validations

        CreateParams = Validate.(
          name: Required.(IsString.(AnyOf.([Stripped, NotBlank, MaxSize.(255)]))),
          section_id: Required.(IsInteger.(Gt.(0))),
          weight: Optional.(IsDecimal.(Gt.(0.0))),
        )

        UpdateParams = Validate.(
          rank: Optional.(IsInteger.(Any)),
        )

        def create(name:, section_id:, weight: Option.None)
          result = CreateParams.(name: name, section_id: section_id, weight: weight)
          return result if result.failure?

          if Paleolog::Repo::Sample.name_exists_within_section?(result.value[:name], result.value[:section_id])
            return Failure.new({ name: :taken })
          end

          attrs = result.value
          max_rank = Paleolog::Repo::Sample
            .all_for_section(section_id)
            .max_by(&:rank)&.rank || 0
          attrs[:rank] = max_rank + 1

          Success.new(Paleolog::Repo::Sample.create(attrs))
        end
      end
    end
  end
end
