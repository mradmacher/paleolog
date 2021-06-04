require_relative 'textizer'

module Paleolog
  module Paleorep
    class SimpleTextizer
      include Paleorep::Textizer

      def textize(object)
        object.to_s
      end

      def valuize(object)
        object
      end
    end
  end
end
