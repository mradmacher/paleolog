# frozen_string_literal: true

require 'csv'

module Paleolog
  # rubocop:disable Metrics/ClassLength
  class Report
    attr_accessor :type, :species_ids, :samples_ids, :view, :charts, :orientation, :show_symbols, :percentages,
                  :reverse_rows, :column_criteria, :counted_group, :marker, :marker_quantity
    attr_reader :column_headers, :row_headers, :values, :splits, :title

    QUANTITY = 'quantity'
    DENSITY = 'density'

    TYPES = [QUANTITY, DENSITY].freeze
    VIEWS = %i[numbers points blocks lines].freeze

    TYPE_NAMES = {
      QUANTITY => 'Quantity',
      DENSITY => 'Density',
    }.freeze
    VIEW_NAMES = {
      numbers: 'Numbers',
      blocks: 'Blocks',
      lines: 'Lines',
      points: 'Points',
    }.freeze
    # rubocop:disable Layout/LineLength
    NOLATIN = /group|bisaccate|algae|pollens?|spores?|foraminiferal|test|linnings|other|and|acritarchs?|spp\.|sp\.|cf\.|[?()]|\d/i.freeze
    # rubocop:enable Layout/LineLength

    ROUND = 1

    class Value
      attr_accessor :value, :object

      def initialize(object, value)
        @value = value
        @object = object
      end
    end

    class SampleTextizer
      include Paleorep::Textizer
      def textize(sample)
        sample.name
      end

      def valuize(sample)
        sample.name
      end
    end

    class SpeciesTextizer
      include Paleorep::Textizer
      def textize(species)
        species.name
      end

      def valuize(species)
        species.name
      end
    end

    class OccurrenceQuantityTextizer
      include Paleorep::Textizer

      def show_symbols?
        @show_symbols
      end

      def initialize(show_symbols: false)
        @show_symbols = show_symbols
      end

      def textize(occurrence)
        if occurrence.nil?
          '0'
        else
          if show_symbols?
            occurrence.normal? ? occurrence.quantity : occurrence.status_symbol
          else
            occurrence.quantity
          end.to_s + (occurrence.uncertain ? Paleolog::CountingSummary::UNCERTAIN_SYMBOL : '')
        end
      end

      def valuize(occurrence)
        occurrence&.quantity
      end
    end

    class OccurrenceDensityTextizer
      include Paleorep::Textizer

      def initialize(density_map = [])
        @density_map = density_map
      end

      def density_map
        @density_map || {}
      end

      def textize(occurrence)
        valuize(occurrence).to_s
      end

      def valuize(occurrence)
        return 0 unless occurrence

        value = density_map.assoc(occurrence)
        return 0 unless value

        value.last.round(ROUND)
      end
    end

    class OccurrencePercentageTextizer
      include Paleorep::Textizer
      attr_reader :sum

      def initialize(sum)
        @sum = sum
      end

      def textize(occurrence)
        valuize(occurrence).to_s
      end

      def valuize(occurrence)
        (100 * occurrence.quantity.to_f / sum).round(2) if occurrence
      end
    end

    def initialize
      @params = %i[section_id counting]
      @row_headers = []
      @column_headers = []
      @values = []
      @splits = []
    end

    # rubocop:disable Metrics/AbcSize
    def self.build(params)
      Report.new.tap do |report|
        report.type = params[:type]
        report.view = params[:view]
        report.show_symbols = params[:show_symbols]
        report.orientation = params[:orientation]
        report.percentages = params[:percentages]
        report.column_criteria = params[:columns]
        report.samples_ids = params[:samples]
        report.reverse_rows = params[:reverse_rows] == '1'
      end
    end
    # rubocop:enable Metrics/AbcSize

    def name
      TYPE_NAMES[@type]
    end

    def param?(param)
      @params.include? param
    end

    def value_row
      @value_row = @values.each if @value_row.nil?
      @value_row
    end

    def filter_row(samples_ids, samples, occurrences)
      filtered_samples = []
      filtered_occurrences = []
      samples.each_with_index do |sample, index|
        if samples_ids.include?(sample.id.to_s)
          filtered_samples << sample
          filtered_occurrences << occurrences[index]
        end
      end
      [filtered_samples, filtered_occurrences]
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def filter_column(column_group, filter)
      if filter['species_ids']
        filtered = []
        column_group.headers.each_with_index do |field, i|
          filtered << i unless filter['species_ids'].include?(field.object.id.to_s)
        end
        shift = 0
        filtered.each do |i|
          column_group.headers.delete_at(i - shift)
          column_group.each_value do |row|
            row.delete_at(i - shift)
          end
          shift += 1
        end
      else
        column_group.headers.clear
        column_group.values.each(&:clear)
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def process_column(column_group, species, samples, occurrences)
      return if species.empty?

      species_textizer = SpeciesTextizer.new
      species.each do |s|
        column_group.headers << Paleorep::Field.new(s, species_textizer)
      end
      occurrence_textizer =
        if type == DENSITY
          density_map = DensityInfo.new(
            counted_group: counted_group,
            marker: marker,
            marker_quantity: marker_quantity,
          ).occurrence_density_map(occurrences.flatten.compact, samples)
          OccurrenceDensityTextizer.new(density_map)
        else
          OccurrenceQuantityTextizer.new(show_symbols: @show_symbols.to_i.positive?)
        end

      occurrences.each_with_index do |row, i|
        row.each_with_index do |occurrence, j|
          column_group.values[i][j] = Paleorep::Field.new(occurrence, occurrence_textizer)
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def post_process_column(column_group, criteria)
      return unless criteria['percentages'] == '1'

      selected_group_id = criteria['group_id'].to_i
      column_group.values.each_with_index do |row, _i|
        row_sum = row.inject(0) do |sum, v|
          toadd = if v.nil? || v.object.nil?
                    0
                  elsif selected_group_id.zero? || selected_group_id == v.object.species.group_id
                    v.value.to_i
                  end

          sum + (toadd || 0)
        end
        textizer = OccurrencePercentageTextizer.new(row_sum)
        row.each do |field|
          field.textizer = textizer if field
        end
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    def get0or_value(value)
      value || 0
    end

    def get0or1(value)
      value ? 1 : 0
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def reduce_column(column_group, criteria)
      return if column_group.headers.empty?

      case criteria['merge']
      when 'sum'
        column_group.combine(Paleorep::Field.new(criteria['header'])) do |row|
          v = row.inject(0) { |sum, field| sum + get0or_value(field.value) }
          Paleorep::Field.new(v.is_a?(Float) ? v.round(ROUND) : v)
        end
      when 'count'
        column_group.combine(Paleorep::Field.new(criteria['header'])) do |row|
          v = row.inject(0) { |sum, field| sum + get0or1(field.value) }
          Paleorep::Field.new(v)
        end
      when 'most_abundant'
        column_group.combine(Paleorep::Field.new(criteria['header'])) do |row|
          max_value = row.max_by { |field| get0or_value(field.value) }
          Paleorep::Field.new(get0or_value(max_value.value))
        end
      when 'second_most_abundant'
        column_group.combine(Paleorep::Field.new(criteria['header'])) do |row|
          max_value = row.max_by { |field| get0or_value(field.value) }
          second_max_value =
            row
            .reject { |field| field == max_value }
            .max_by { |field| get0or_value(field.value) }
          Paleorep::Field.new(get0or_value(second_max_value.value))
        end
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def process_computed_column(report, criteria)
      return if criteria['computed'].nil? || criteria['computed'].empty?

      a_idx = 0
      b_idx = 1
      c_idx = 2

      return unless (criteria['computed'] =~ %r{^([ ABC+/()*-]|\d)+$}).zero?

      column_group = report.append_column_group
      column_group.headers << Paleorep::Field.new(criteria['header'])
      report.headers.each_with_index do |_, i|
        formula = criteria['computed'].dup
        cga = report.column_groups[a_idx]
        cgb = report.column_groups[b_idx]
        cgc = report.column_groups[c_idx]

        fa = (cga ? cga.values[i].first : nil)
        fb = (cgb ? cgb.values[i].first : nil)
        fc = (cgc ? cgc.values[i].first : nil)

        a = (fa ? fa.value : 0)
        b = (fb ? fb.value : 0)
        c = (fc ? fc.value : 0)

        formula.gsub!(/A/, a.to_f.to_s)
        formula.gsub!(/B/, b.to_f.to_s)
        formula.gsub!(/C/, c.to_f.to_s)
        begin
          # rubocop:disable Security/Eval
          result = eval formula
          # rubocop:enable Security/Eval
          column_group.values[i][0] = Paleorep::Field.new(result.infinite? ? nil : result.round(ROUND))
        rescue ZeroDivisionError
          column_group.values[i][0] = Paleorep::Field.new(nil)
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def concat_values(report)
      @values = Array.new(report.headers.size)
      report.column_groups.each do |column_group|
        next if column_group.values.empty?

        column_group.values.each_with_index do |row, i|
          @values[i] = [] unless @values[i].is_a? Array
          @values[i].concat(row.map(&:text))
        end
      end
    end

    def concat_column_headers(report)
      @column_headers = []
      report.column_groups.each do |column_group|
        @column_headers.concat(column_group.headers.map(&:text)) unless column_group.headers.empty?
      end
    end

    def concat_row_headers(report)
      @row_headers = []
      @row_headers.concat(report.headers.map(&:text))
    end

    def concat_splits(report)
      @splits = []
      report.column_groups.each do |column_group|
        @splits << (@splits.last || -1) + column_group.headers.size unless column_group.headers.empty?
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def generate(occurrences, samples)
      samples_summary, species_summary, occurrences_summary =
        Paleolog::CountingSummary.new(occurrences).summary(samples)

      report = Paleolog::Paleorep::Report.new
      samples_summary, occurrences_summary = filter_row(samples_ids, samples_summary, occurrences_summary)
      if reverse_rows
        samples_summary.reverse!
        occurrences_summary.reverse!
      end
      sample_textizer = SampleTextizer.new
      samples_summary.each do |sample|
        report.add_row(Paleolog::Paleorep::Field.new(sample, sample_textizer))
      end

      # rubocop:disable Style/CombinableLoops
      @column_criteria.each_value do |criteria|
        column_group = report.append_column_group
        process_column(column_group, species_summary, samples_summary, occurrences_summary)
        post_process_column(column_group, criteria)
        filter_column(column_group, criteria)
        reduce_column(column_group, criteria)
      end

      @column_criteria.each_value do |criteria|
        process_computed_column(report, criteria)
      end
      # rubocop:enable Style/CombinableLoops

      concat_column_headers(report)
      concat_row_headers(report)
      concat_values(report)
      concat_splits(report)
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def self.model_name
      ActiveModel::Name.new(self, false)
    end

    def to_csv
      CSV.generate(col_sep: ',') do |csv|
        csv << [nil].concat(@column_headers)
        @row_headers.each do |vheader|
          begin
            csv << [vheader].concat(value_row.next.map { |i| (i.to_s == '0' ? nil : i) })
          rescue StopIteration
            csv << [vheader].concat(@row_headers.size.times.map { |_i| nil })
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
