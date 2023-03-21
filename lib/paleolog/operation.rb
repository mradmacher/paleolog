# frozen_string_literal: true

module Paleolog
  module Operation
    UNAUTHORIZED = :unauthorized
    UNAUTHORIZED_RESULT = [nil, { general: UNAUTHORIZED }]

    IdRules = Pp.required.(Pp.integer.(Pp.gt.(0)))
    NameRules = Pp.string.(
      Pp.all_of.([Pp.stripped, Pp.not_blank, Pp.max_size.(255)]),
    )
  end
end

require 'paleolog/operation/choice'
require 'paleolog/operation/field'
require 'paleolog/operation/group'
require 'paleolog/operation/occurrence'
require 'paleolog/operation/project'
require 'paleolog/operation/sample'
require 'paleolog/operation/section'
require 'paleolog/operation/species'
