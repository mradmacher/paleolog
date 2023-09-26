# frozen_string_literal: true

require 'paleolog/operation/params'

module Paleolog
  module Operation
    UNAUTHORIZED = :unauthorized
    UNAUTHENTICATED = :unauthenticated
    TAKEN = :taken

    TOO_LONG = Params::TOO_LONG
    BLANK = Params::BLANK
    MISSING = Params::MISSING
    NON_DECIMAL = Params::NON_DECIMAL
    NON_INTEGER = Params::NON_INTEGER
    NOT_GT = Params::NOT_GT
    UNAUTHENTICATED_RESULT = { general: UNAUTHENTICATED }.freeze
    UNAUTHORIZED_RESULT = { general: UNAUTHORIZED }.freeze
  end
end

require 'paleolog/operation/base_operation'
require 'paleolog/operation/choice'
require 'paleolog/operation/counting'
require 'paleolog/operation/field'
require 'paleolog/operation/group'
require 'paleolog/operation/occurrence'
require 'paleolog/operation/project'
require 'paleolog/operation/sample'
require 'paleolog/operation/section'
require 'paleolog/operation/species'
