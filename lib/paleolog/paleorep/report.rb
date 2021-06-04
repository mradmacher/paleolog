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
        self.headers << field
      end

      def append_column_group
        column_group = ColumnGroup.new
        self.headers.size.times do
          column_group.values << []
        end
        self.column_groups << column_group
        column_group
      end
    end
  end
end
