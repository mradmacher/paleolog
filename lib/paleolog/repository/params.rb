# frozen_string_literal: true

require 'param_param'
require 'param_param/std'

module Paleolog
  module Repository
    module Params
      include ParamParam
      include ParamParam::Std

      def self.soft_integer
        lambda { |fn, option|
          fn.call(Optiomist.some(option.value.to_i))
        }.curry
      end

      IdRules = integer.(gt.(0))
      SoftIdRules = soft_integer.(gt.(0))
      NameRules = string.(
        all_of.([stripped, not_blank, max_size.(255)]),
      )
      DescriptionRules = blank_to_nil_or.(string.(max_size.(4096)))
    end
  end
end
