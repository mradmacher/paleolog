# frozen_string_literal: true

module Paleolog
  module Paleorep
    class ColumnGroup
      def headers
        @headers ||= []
      end

      def values
        @values ||= []
      end

      def each_value(&)
        values.each(&)
      end

      def combine(header)
        values.each_with_index do |row, i|
          values[i].replace([yield(row)])
        end
        headers.replace([header])
      end
    end
  end
end
