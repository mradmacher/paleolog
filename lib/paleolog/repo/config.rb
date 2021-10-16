# frozen_string_literal: true

require 'singleton'
require 'forwardable'
require 'sequel'

module Paleolog
  module Repo
    class Config
      include Singleton
      #       def configuration
      #         @configuration = ROM::Configuration.new(:sql,
      #           "sqlite:#{File.expand_path(File.join(__dir__, '..', '..', '..', 'db', "#{ENV['RACK_ENV']}.sqlite"))}"
      #         ).tap do |conf|
      #           conf.relation(:choices) do
      #             schema(infer: true) do
      #               associations do
      #                 belongs_to :field
      #               end
      #             end
      #             #struct_namespace Paleolog::Entities
      #             #auto_struct true
      #           end
      #
      #           conf.relation(:fields) do
      #             schema(infer: true) do
      #               associations do
      #                 belongs_to :group
      #                 has_many :choices
      #               end
      #             end
      #           end
      #
      #           conf.relation(:features) do
      #             schema(infer: true) do
      #               associations do
      #                 belongs_to :choice
      #                 belongs_to :species
      #               end
      #             end
      #           end
      #
      #           conf.relation(:groups) do
      #             schema(infer: true) do
      #               associations do
      #                 has_many :species
      #                 has_many :fields
      #               end
      #             end
      #           end
      #
      #           conf.relation(:species) do
      #             schema(infer: true) do
      #               associations do
      #                 belongs_to :group
      #                 has_many :features
      #                 has_many :choices, through: :features
      #                 has_many :images
      #                 has_many :occurrences
      #               end
      #             end
      #           end
      #
      #           conf.relation(:images) do
      #             schema(infer: true) do
      #               associations do
      #                 belongs_to :species
      #               end
      #             end
      #           end
      #
      #           conf.relation(:projects) do
      #             schema(infer: true) do
      #               associations do
      #                 has_many :research_participations
      #                 has_many :users, through: :research_participations
      #                 has_many :sections
      #                 has_many :countings
      #                 has_many :samples, through: :sections
      #               end
      #             end
      #           end
      #
      #           conf.relation(:research_participations) do
      #             schema(infer: true) do
      #               associations do
      #                 belongs_to :project
      #                 belongs_to :user
      #               end
      #             end
      #           end
      #
      #           conf.relation(:users) do
      #             schema(infer: true) do
      #               associations do
      #                 has_many :research_participations
      #                 has_many :projects, through: :research_participations
      #               end
      #             end
      #           end
      #
      #           conf.relation(:sections) do
      #             schema(infer: true) do
      #               associations do
      #                 belongs_to :project
      #                 has_many :samples
      #                 has_many :occurrences, through: :samples
      #               end
      #             end
      #           end
      #
      #           conf.relation(:countings) do
      #             schema(infer: true) do
      #               associations do
      #                 belongs_to :project
      #                 belongs_to :group
      #                 belongs_to :species
      #                 has_many :occurrences
      #               end
      #             end
      #           end
      #
      #           conf.relation(:samples) do
      #             schema(infer: true) do
      #               associations do
      #                 belongs_to :section
      #                 has_many :occurrences
      #               end
      #             end
      #           end
      #
      #           conf.relation(:occurrences) do
      #             schema(infer: true) do
      #               associations do
      #                 belongs_to :species
      #                 belongs_to :sample
      #                 belongs_to :section, through: :samples
      #                 belongs_to :counting
      #               end
      #             end
      #           end
      #         end
      #       end

      def db
        @db = Sequel.connect("sqlite:#{File.expand_path(File.join(__dir__, '..', '..', '..', 'db',
                                                                  "#{ENV['RACK_ENV']}.sqlite"))}")
      end

      class << self
        extend Forwardable

        def_delegators(
          :instance,
          :db
        )
      end
    end
  end
end
