# frozen_string_literal: true

module Paleolog
  module Paleorep
    class Report
      def headers
        @headers ||= []
      end

      def column_groups
        @column_groups ||= []
      end

      def add_row(field)
        headers << field
      end

      def append_column_group
        column_group = ColumnGroup.new
        headers.size.times do
          column_group.values << []
        end
        column_groups << column_group
        column_group
      end
    end
  end
end
