require_relative 'simple_textizer'

module Paleorep
  class Field
    attr_reader :object
    attr_accessor :textizer

    def initialize(object, textizer = Paleorep::SimpleTextizer.new)
      @object = object
      @textizer = textizer
    end

    def text
      textizer.textize(object)
    end

    def value
      textizer.valuize(object)
    end
  end
end
