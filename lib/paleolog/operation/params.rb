# frozen_string_literal: true

require 'param_param'
require 'param_param/std'

module Paleolog
  module Operation
    module Params
      include ParamParam
      include ParamParam::Std

      IdRules = integer.(gt.(0))
      NameRules = string.(
        all_of.([stripped, not_blank, max_size.(255)]),
      )
      DescriptionRules = blank_to_nil_or.(string.(max_size.(4096)))
    end
  end
end
