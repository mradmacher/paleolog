module Paleolog
  module Paleorep
    class ColumnGroup
      def headers
        @headers ||= []
      end

      def values
        @values ||= []
      end

      def reduce(header)
        self.values.each_with_index do |row, i|
          self.values[i].replace([yield(row)])
        end
        self.headers.replace([header])
      end
    end
  end
end
