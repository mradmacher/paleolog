# frozen_string_literal: true

require 'dry-types'

module Paleolog
  module Contract
    module Types
      include Dry::Types()

      StrippedString = Types::String.constructor(&:strip)
    end
  end
end
