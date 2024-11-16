# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity
module Paleolog
  module Paleorep
    class ChartView
      attr_reader :font_size,
                  :stroke_width

      def initialize(report)
        @font_size = 10
        @stroke_width = 1
        @report = report
      end

      def lines
        if @lines.nil?
          @lines = []
          @lines << 0
          @report.splits.each do |split|
            @lines << (split + 1)
          end
        end
        @lines
      end

      def row_header_width
        if @row_header_width.nil?
          @row_header_width = 0
          @report.row_headers.each do |header|
            h = header
            computed = (h.to_s.length + 1 + ((h.to_s.length / 3) * 0.5)) * @font_size / 2
            @row_header_width = computed if computed > @row_header_width
          end
        end
        @row_header_width
      end

      def column_header_height
        if @column_header_height.nil?
          @column_header_height = 0
          @report.column_headers.flatten.each do |header|
            h = header
            computed = (h.to_s.length * @font_size / 2) + @font_size
            @column_header_height = computed if computed > @column_header_height
          end
        end
        @column_header_height
      end

      def col_widths
        if @col_widths.nil?
          @col_widths = []
          @report.each_value do |row|
            row.each_with_index do |col, colidx|
              existing = @col_widths[colidx].nil? ? 0 : @col_widths[colidx]

              computed = case @report.view.to_sym
                         when :numbers
                           (col.to_s.length + 1 + ((col.to_s.length / 2) * 0.5)) * @font_size / 2
                         when :points
                           @font_size + 1
                         when :blocks
                           [(col.to_i / 2) + 1 + 2, @font_size].max
                         when :lines
                           [(col.to_i / 2) + 1 + 4, @font_size].max
                         end

              @col_widths[colidx] = computed if computed > existing
            end
          end
        end
        @col_widths
      end

      def col_height
        @font_size
      end

      def cells
        if @cells.nil?
          @cells = []
          lines_count = 0
          col_width = 0
          @report.column_headers.flatten.size.times do |i|
            @cells[i] = []
            lines_count += 1 if lines.include?(i)
            @report.values.each_with_index do |row, j|
              x = @stroke_width + 1 + row_header_width + col_width + (@stroke_width * lines_count) + lines_count
              y = col_height * j
              @cells[i][j] = [x, y, row[i]]
            end
            col_width += col_widths[i]
          end
        end
        @cells
      end

      def columns
        if @columns.nil?
          @columns = []
          lines_count = 0
          col_width = 0
          @report.column_headers.flatten.each_with_index do |_header, i|
            lines_count += 1 if lines.include?(i)
            x = @stroke_width + row_header_width + col_width + (@stroke_width * lines_count) + lines_count
            y = - col_height
            width = col_widths[i]
            height = (rows_count * col_height) + 1
            @columns[i] = [x, y, width, height]

            col_width += col_widths[i]
          end
        end
        @columns
      end

      def column_headers
        if @column_headers.nil?
          @column_headers = []
          lines_count = 0
          col_width = 0
          @report.column_headers.flatten.each_with_index do |header, i|
            lines_count += 1 if lines.include?(i)
            x = @stroke_width + row_header_width + (@stroke_width * lines_count) + col_height
            y = - col_height - @stroke_width - 1
            @column_headers[i] = [[x, y], [0, col_width], header]
            col_width += col_widths[i]
          end
        end
        @column_headers
      end

      def row_headers
        if @row_headers.nil?
          @row_headers = []
          @report.row_headers.each_with_index do |header, i|
            y = i * col_height
            x1 = (@stroke_width / 2) + row_header_width
            x2 = col_widths_sum + row_header_width + (@stroke_width * (lines.size + 1)) + lines.size
            @row_headers[i] = [[x1, y], [x2, y], header]
          end
        end
        @row_headers
      end

      def cols_count
        @report.column_headers.flatten.size
      end

      def rows_count
        @report.row_headers.size
      end

      def col_widths_sum(line = nil)
        (line.nil? ? col_widths : col_widths[0...line]).inject(0) { |sum, e| sum + e }
      end

      def rows_header
        if @rows_header.nil?
          @rows_header = {}
          @rows_header[:all] = [@stroke_width + 1, -col_height - @stroke_width - 1]
          @rows_header[:left] = [0, col_height]
          @rows_header[:right] =
            [0, col_widths_sum + (2 * row_header_width) + (@stroke_width * lines.size)]
        end
        @rows_header
      end

      def border
        if @border.nil?
          x = @stroke_width / 2
          y = - col_height - (@stroke_width / 2)
          width = (@stroke_width / 2) + (2 * row_header_width) + col_widths_sum + (@stroke_width * lines.size) +
                  lines.size + 2 + (@stroke_width / 2) + 1
          height = (rows_count * col_height) + @stroke_width + 1
          @border = [x, y, width, height]
        end
        @border
      end

      def line_positions
        if @line_positions.nil?
          @line_positions = []
          lines.each_with_index do |line, i|
            x = @stroke_width + 1 + row_header_width + col_widths_sum(line) +
                (@stroke_width * i) + i + (@stroke_width / 2)
            y1 = -col_height
            y2 = (rows_count * col_height) - col_height + @stroke_width + 1
            @line_positions[i] = [x, y1, y2]
          end
        end
        @line_positions
      end
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity
