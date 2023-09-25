# frozen_string_literal: true

module Paleolog
  module Operation
    UNAUTHORIZED = :unauthorized
    UNAUTHENTICATED = :unauthenticated
    TAKEN = :taken

    TOO_LONG = PaPa::TOO_LONG
    BLANK = PaPa::BLANK
    MISSING = PaPa::MISSING
    NON_DECIMAL = PaPa::NON_DECIMAL
    NON_INTEGER = PaPa::NON_INTEGER
    NOT_GT = PaPa::NOT_GT
    UNAUTHENTICATED_RESULT = { general: UNAUTHENTICATED }.freeze
    UNAUTHORIZED_RESULT = { general: UNAUTHORIZED }.freeze

    IdRules = PaPa.integer.(PaPa.gt.(0))
    NameRules = PaPa.string.(
      PaPa.all_of.([PaPa.stripped, PaPa.not_blank, PaPa.max_size.(255)]),
    )
    DescriptionRules = PaPa.blank_to_nil_or.(PaPa.string.(PaPa.max_size.(4096)))
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
