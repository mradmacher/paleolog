# frozen_string_literal: true

require 'param_param'
require 'param_param/std'

module PaPa
  include ParamParam
  include ParamParam::Std
end

require 'paleolog/entities'
require 'paleolog/authorizer'
require 'paleolog/repo'
require 'paleolog/counting_summary'
require 'paleolog/density_info'
require 'paleolog/operation'
require 'paleolog/paleorep/chart_view'
require 'paleolog/paleorep/column_group'
require 'paleolog/paleorep/field'
require 'paleolog/paleorep/report'
require 'paleolog/paleorep/simple_textizer'
require 'paleolog/paleorep/textizer'
require 'paleolog/report'
