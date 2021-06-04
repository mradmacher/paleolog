# frozen_string_literal: true

require 'rom'

module Paleolog
  module Entities
    class Group < ROM::Struct; end
    class Species < ROM::Struct; end
    class Project < ROM::Struct; end
    class Counting < ROM::Struct; end
    class Section < ROM::Struct; end
    class Sample < ROM::Struct; end
    class Occurrence < ROM::Struct; end
  end
end
