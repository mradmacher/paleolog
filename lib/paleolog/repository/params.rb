# frozen_string_literal: true

require 'param_param'
require 'param_param/std'

module Paleolog
  module Repository
    module Params
      include ParamParam
      include ParamParam::Std

      # Verifies if provided value is nil, empty string or a string consisting only from spaces.
      def self.blank?(value)
        value.nil? || (value.is_a?(String) && value.strip.empty?)
      end

      NOT_NIL = ->(option) { option.some? && option.value.nil? ? Failure.new(MISSING_ERR) : Success.new(option) }
      NOT_BLANK = ->(option) { option.some? && blank?(option.value) ? Failure.new(MISSING_ERR) : Success.new(option) }

      # Converts blank value to nil or passes non blank value to next action.
      BLANK_TO_NIL_OR = lambda do |fn, option|
        blank?(option.value) ? Success.new(Optiomist.some(nil)) : fn.call(option)
      end.curry

      SOFT_INTEGER = lambda { |fn, option| fn.call(Optiomist.some(option.value.to_i)) }.curry

      ID = ALL_OF.([NOT_NIL, INTEGER, GT.(0)])
      SLUG_ID = SOFT_INTEGER.(GT.(0))
      NAME = ALL_OF.([NOT_BLANK, STRING, STRIPPED, MIN_SIZE.(1), MAX_SIZE.(255)])
      DESCRIPTION = BLANK_TO_NIL_OR.(ALL_OF.([STRING, MAX_SIZE.(4096)]))
    end
  end
end
