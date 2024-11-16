# frozen_string_literal: true

require 'paleolog/entities'
require 'paleolog/authorizer'
require 'paleolog/config'
require 'paleolog/counting_summary'
require 'paleolog/density_info'
require 'paleolog/paleorep/chart_view'
require 'paleolog/paleorep/column_group'
require 'paleolog/paleorep/field'
require 'paleolog/paleorep/report'
require 'paleolog/paleorep/simple_textizer'
require 'paleolog/paleorep/textizer'
require 'paleolog/report'
require 'paleolog/repository'

module Paleolog
  def self.db
    Config.db
  end
end
