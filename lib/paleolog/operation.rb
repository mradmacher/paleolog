# frozen_string_literal: true

require 'paleolog/operation/params'

module Paleolog
  module Operation
    UNAUTHORIZED = :unauthorized
    UNAUTHENTICATED = :unauthenticated
    TAKEN = :taken

    UNAUTHENTICATED_RESULT = { general: UNAUTHENTICATED }.freeze
    UNAUTHORIZED_RESULT = { general: UNAUTHORIZED }.freeze
  end
end

require 'paleolog/operation/base_operation'
require 'paleolog/operation/common_validations'
require 'paleolog/operation/account'
require 'paleolog/operation/choice'
require 'paleolog/operation/counting'
require 'paleolog/operation/field'
require 'paleolog/operation/group'
require 'paleolog/operation/occurrence'
require 'paleolog/operation/project'
require 'paleolog/operation/sample'
require 'paleolog/operation/section'
require 'paleolog/operation/species'
