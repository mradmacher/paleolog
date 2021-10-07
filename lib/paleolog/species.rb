# frozen_string_literal: true

require 'rom'

module Paleolog
  class Species < ROM::Struct
    attribute? :id, Paleolog::Types::Integer
    attribute :name, Paleolog::Types::String
    attribute :verified, Paleolog::Types::Bool.default(false)
    attribute? :description, Paleolog::Types::String
    attribute? :environmental_preferences, Paleolog::Types::String

    attribute :updated_at, Paleolog::Types::DateTime.default(DateTime.now.freeze)
    attribute :created_at, Paleolog::Types::DateTime.default(DateTime.now.freeze)

    # attribute? :group_id, Paleolog::Types::Integer
    attribute? :group, Types::Instance(Paleolog::Group)

    def images
      []
    end

    def field_features
      {}
    end
  end
end
