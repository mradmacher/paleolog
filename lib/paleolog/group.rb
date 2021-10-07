# frozen_string_literal: true

require 'rom'

module Paleolog
  class Group < ROM::Struct
    attribute? :id, Paleolog::Types::Integer
    attribute :name, Paleolog::Types::String
  end
end
