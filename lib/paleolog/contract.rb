# frozen_string_literal: true

require 'dry/schema'
require_relative './counting_summary'

module Paleolog
  module Contract
    module Types
      include Dry::Types()

      StrippedString = Types::String.constructor(&:strip)
    end

    GroupSchema = Dry::Schema.Params do
      required(:name).value(Types::StrippedString, :filled?, max_size?: 255)
    end

    ProjectSchema = Dry::Schema.Params do
      required(:name).value(Types::StrippedString, :filled?, max_size?: 255)
    end

    SpeciesSchema = Dry::Schema.Params do
      required(:name).value(Contract::Types::StrippedString, :filled?, max_size?: 255)
      required(:group_id).filled(:integer)
      optional(:description).value(:string, max_size?: 4096)
      optional(:environmental_preferences).value(:string, max_size?: 4096)
    end

    ImageSchema = Dry::Schema.Params do
      # "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      # "created_at" datetime, "updated_at" datetime, "species_id" integer, "image_file_name" varchar(255
      # ), "image_content_type" varchar(255), "image_file_size" integer, "sample_id" integer, "ef" varchar(255)
    end

    FieldSchema = Dry::Schema.Params do
      required(:name).value(Contract::Types::StrippedString, :filled?, max_size?: 255)
      required(:group_id).filled(:integer)
    end

    ChoiceSchema = Dry::Schema.Params do
      required(:name).value(Contract::Types::StrippedString, :filled?, max_size?: 255)
      required(:field_id).filled(:integer)
    end

    SectionSchema = Dry::Schema.Params do
      required(:name).value(Contract::Types::StrippedString, :filled?, max_size?: 255)
      required(:project_id).filled(:integer)
    end

    SampleSchema = Dry::Schema.Params do
      required(:section_id).filled(:integer)
      required(:rank).filled(:integer)
      required(:name).value(Contract::Types::StrippedString, :filled?, max_size?: 255)
      optional(:weight).maybe(:decimal, gt?: 0)
    end

    OccurrenceSchema = Dry::Schema.Params do
      required(:counting_id).filled(:integer)
      required(:sample_id).filled(:integer)
      required(:species_id).filled(:integer)
      required(:rank).filled(:integer)
      required(:status).filled(
        :integer,
        included_in?: [
          Paleolog::CountingSummary::NORMAL,
          Paleolog::CountingSummary::OUTSIDE_COUNT,
          Paleolog::CountingSummary::CARVING,
          Paleolog::CountingSummary::REWORKING
        ],
      )
    end
  end
end

require 'paleolog/contract/group'
require 'paleolog/contract/project'
require 'paleolog/contract/species'
require 'paleolog/contract/choice'
require 'paleolog/contract/section'
require 'paleolog/contract/sample'
require 'paleolog/contract/occurrence'
require 'paleolog/contract/density'
