# frozen_string_literal: true

module Paleolog
  module Operation
    UNAUTHORIZED = :unauthorized
    UNAUTHENTICATED = :unauthenticated
    TAKEN = :taken
    TOO_LONG = ParamParam::TOO_LONG
    BLANK = ParamParam::BLANK
    MISSING = ParamParam::MISSING
    NON_DECIMAL = ParamParam::NON_DECIMAL
    NON_INTEGER = ParamParam::NON_INTEGER
    NOT_GT = ParamParam::NOT_GT
    UNAUTHENTICATED_RESULT = [nil, { general: UNAUTHENTICATED }].freeze
    UNAUTHORIZED_RESULT = [nil, { general: UNAUTHORIZED }].freeze

    IdRules = Pp.integer.(Pp.gt.(0))
    NameRules = Pp.string.(
      Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]),
    )
    DescriptionRules = Pp.blank_to_nil_or.(Pp.string.(Pp.max_size.(4096)))
  end
end

require 'paleolog/operation/helpers'
require 'paleolog/operation/choice'
require 'paleolog/operation/counting'
require 'paleolog/operation/field'
require 'paleolog/operation/group'
require 'paleolog/operation/occurrence'
require 'paleolog/operation/project'
require 'paleolog/operation/sample'
require 'paleolog/operation/section'
require 'paleolog/operation/species'
