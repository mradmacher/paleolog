# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Report do
  before do
    project = Paleolog::Project.new(name: 'Test')
    @section = Paleolog::Section.new(project: project, name: 'Section1')
    @counting = Paleolog::Counting.new(project: project, name: 'Counting1')
    @samples = []
    [100, 200, 300].each_with_index do |depth, index|
      @samples << Paleolog::Sample.new(
        id: index,
        section: @section,
        name: "Sample#{depth}",
        bottom_depth: depth,
        weight: 10.0,
      )
    end
    @groups = [Paleolog::Group.new(name: 'Group1'), Paleolog::Group.new(name: 'Group2')]

    @species = []
    @groups.each_with_index do |group, i|
      @species[i] = []
      4.times { |j| @species[i] << Paleolog::Species.new(id: (i * 10) + j, group: group, name: "Species#{i}#{j}") }
    end

    @occurrences = []
    # sample, rank, group, species
    [
      [0, 0, 0, 2], [0, 1, 0, 3], [0, 2, 1, 0],
      [1, 0, 0, 0], [1, 1, 0, 1], [1, 2, 0, 3], [1, 3, 0, 2], [1, 4, 1, 0],
      [2, 0, 0, 1], [2, 1, 0, 2], [2, 2, 1, 1], [2, 3, 1, 2]
    ].each do |value|
      @occurrences << Paleolog::Occurrence.new(
        counting: @counting,
        sample: @samples[value[0]],
        species: @species[value[2]][value[3]],
        rank: value[1],
        quantity: (1..100).to_a.sample,
        status: (value[2]).zero? ? Paleolog::Occurrence::NORMAL : Paleolog::Occurrence::OUTSIDE_COUNT,
      )
    end
  end

  describe 'most abundant species' do
    before do
      @samples_summary, @species_summary, @occurrences_summary =
        Paleolog::CountingSummary.new(@occurrences).summary(@samples)
      @report = Paleolog::Report.build(
        type: Paleolog::Report::QUANTITY,
        samples: @samples_summary.map { |s| s.id.to_s },
        columns: {
          '0' => {
            'species_ids' => @species_summary.map { |s| s.id.to_s },
            'merge' => 'most_abundant',
            'header' => 'Most Abundant',
          },
        },
      )
      @report.generate(@occurrences, @samples)
    end

    it 'generate proper values' do
      expected = []
      @occurrences_summary.each_with_index do |row, i|
        expected[i] = row.max_by { |o| o&.quantity ? o.quantity : 0 }.quantity.to_s
      end
      expected.each_with_index do |v, i|
        assert_equal v, @report.values[i][0]
      end
    end
  end

  describe 'second most abundant species' do
    before do
      @samples_summary, @species_summary, @occurrences_summary =
        Paleolog::CountingSummary.new(@occurrences).summary(@samples)
      @report = Paleolog::Report.build(
        type: Paleolog::Report::QUANTITY,
        samples: @samples_summary.map { |s| s.id.to_s },
        columns: {
          '0' => {
            'species_ids' => @species_summary.map { |s| s.id.to_s },
            'merge' => 'second_most_abundant',
            'header' => 'Most Abundant',
          },
        },
      )
      @report.generate(@occurrences, @samples)
    end

    it 'generate proper values' do
      expected = []
      @occurrences_summary.each_with_index do |row, i|
        most_abundant = row.max_by { |o| o&.quantity ? o.quantity : 0 }
        second_most_abundant = row.reject { |v| v == most_abundant }.max_by { |o| o&.quantity ? o.quantity : 0 }
        expected[i] = second_most_abundant&.quantity&.to_s
      end
      expected.each_with_index do |v, i|
        assert_equal v, @report.values[i][0]
      end
    end
  end

  describe 'count' do
    before do
      @samples_summary, @species_summary, @occurrences_summary =
        Paleolog::CountingSummary.new(@occurrences).summary(@samples)
      @report = Paleolog::Report.build(
        type: Paleolog::Report::QUANTITY,
        samples: @samples_summary.map { |s| s.id.to_s },
        columns: {
          '0' => {
            'species_ids' => @species_summary.map { |s| s.id.to_s },
            'merge' => 'count',
            'header' => 'Species',
          },
        },
      )
      @report.generate(@occurrences, @samples)
    end

    it 'generate proper row headers' do
      assert_equal @samples_summary.map(&:name), @report.row_headers
    end

    it 'generate proper column headers' do
      assert_equal 1, @report.column_headers.size
      assert_equal ['Species'], @report.column_headers
    end

    it 'generate proper values' do
      assert_equal '3', @report.values[0][0]
      assert_equal '5', @report.values[1][0]
      assert_equal '4', @report.values[2][0]
    end
  end

  describe 'computed' do
    before do
      @samples_summary, @species_summary, @occurrences_summary =
        Paleolog::CountingSummary.new(@occurrences).summary(@samples)
      @report = Paleolog::Report.build(
        type: Paleolog::Report::QUANTITY,
        samples: @samples_summary.map { |s| s.id.to_s },
        columns: {
          '0' => {
            'species_ids' => @species_summary.map { |s| s.id.to_s },
            'merge' => 'count',
            'header' => 'Species Count',
          },
          '1' => {
            'species_ids' => @species_summary.map { |s| s.id.to_s },
            'merge' => 'sum',
            'header' => 'Species Sum',
          },
          '2' => {
            'computed' => 'A/B',
            'header' => 'Count/Sum',
          },
          '3' => {
            'computed' => 'B/A',
            'header' => 'Sum/Count',
          },
          '4' => {
            'computed' => '(A - B) / (A + B)',
            'header' => 'Ratio',
          },
        },
      )
      @report.generate(@occurrences, @samples)
    end

    it 'generate proper column headers' do
      assert_equal 5, @report.column_headers.size
      assert_equal ['Species Count', 'Species Sum', 'Count/Sum', 'Sum/Count', 'Ratio'], @report.column_headers
    end

    it 'generate proper values' do
      @occurrences_summary.each_with_index do |row, i|
        sum = row.inject(0) { |result, v| result + (v&.quantity || 0) }
        count = row.inject(0) { |result, v| result + (v.nil? ? 0 : 1) }
        count_sum = (sum.zero? ? 0 : (count.to_f / sum).round(1))
        sum_count = (count.zero? ? 0 : (sum.to_f / count).round(1))
        ratio = ((sum + count).zero? ? 0 : ((count - sum).to_f / (count + sum)).round(1))
        expected = [count.to_s, sum.to_s, count_sum.to_s, sum_count.to_s, ratio.to_s]
        assert_equal expected, @report.values[i]
      end
    end
  end

  describe 'quantities' do
    before do
      @samples_summary, @species_summary, @occurrences_summary =
        Paleolog::CountingSummary.new(@occurrences).summary(@samples)
      @report = Paleolog::Report.build(
        type: Paleolog::Report::QUANTITY,
        samples: @samples_summary.map { |s| s.id.to_s },
        columns: { '0' => { 'species_ids' => @species_summary.map { |s| s.id.to_s } } },
      )
      @report.generate(@occurrences, @samples)
    end

    it 'generate proper row headers' do
      assert_equal @samples_summary.map(&:name), @report.row_headers
    end

    it 'generate proper column headers' do
      assert_equal @species_summary.map(&:name), @report.column_headers
    end

    it 'generate proper values' do
      @samples_summary.each_with_index do |_sample, row|
        @occurrences_summary[row].each_with_index do |occurrence, column|
          expected = '0'
          unless occurrence.nil?
            expected = occurrence.quantity.to_s
            expected += Paleolog::CountingSummary::UNCERTAIN_SYMBOL if occurrence.uncertain
          end
          assert_equal expected, @report.values[row][column]
        end
      end
    end
  end

  describe 'percentages' do
    before do
      @samples_summary, @species_summary, @occurrences_summary =
        Paleolog::CountingSummary.new(@occurrences).summary(@samples)
      @report = Paleolog::Report.build(
        type: Paleolog::Report::QUANTITY,
        samples: @samples_summary.map { |s| s.id.to_s },
        columns: {
          '0' => {
            'species_ids' => @species_summary.map { |s| s.id.to_s },
            'percentages' => '1',
          },
        },
      )
      @report.generate(@occurrences, @samples)
    end

    it 'generate proper row headers' do
      assert_equal @samples_summary.map(&:name), @report.row_headers
    end

    it 'generate proper column headers' do
      assert_equal @species_summary.map(&:name), @report.column_headers
    end

    it 'generate proper values' do
      @samples_summary.each_with_index do |_sample, row|
        row_sum = @occurrences_summary[row].compact.inject(0) { |sum, occ| sum + (occ.quantity || 0) }
        perc_sum = 0
        @occurrences_summary[row].each_with_index do |occurrence, column|
          expected = ''
          expected = (occurrence.quantity.to_f / row_sum * 100).round(2).to_s unless occurrence.nil?
          perc_sum += @report.values[row][column].to_f
          assert_equal expected, @report.values[row][column]
        end
        assert_in_delta(100.0, perc_sum.round(1))
      end
    end
  end

  describe 'densities' do
    before do
      @counted_group = @groups[0]
      @marker = @species[1][0]
      @marker_quantity = 30
      @samples_summary, @species_summary, @occurrences_summary =
        Paleolog::CountingSummary.new(@occurrences).summary(@samples)
      @selected_species_ids = @species_summary.select { |s| s.group == @counted_group }.map { |s| s.id.to_s }
      @report = Paleolog::Report.build(
        type: Paleolog::Report::DENSITY,
        samples: @samples_summary.map { |s| s.id.to_s },
        columns: {
          '0' => { 'species_ids' => @selected_species_ids },
          '1' => {
            'species_ids' => @selected_species_ids,
            'merge' => 'sum',
            'header' => 'Density',
          },
        },
      )
      @report.counted_group = @counted_group
      @report.marker = @marker
      @report.marker_quantity = @marker_quantity
      @report.generate(@occurrences, @samples)
      @density_info = Paleolog::DensityInfo.new(counted_group: @counted_group, marker: @marker,
                                                marker_quantity: @marker_quantity,)
    end

    it 'generate proper row headers' do
      assert_equal @samples_summary.map(&:name), @report.row_headers
    end

    it 'generate proper column headers' do
      assert_equal [@species[0][2].name, @species[0][3].name, @species[0][0].name, @species[0][1].name, 'Density'],
                   @report.column_headers
    end

    it 'generate proper values dupa' do
      density_map = @density_info.occurrence_density_map(@occurrences, @samples)
      @samples_summary.each_with_index do |sample, row|
        sample_density = @density_info.group_density(@occurrences, sample)&.round(1)

        expected = @selected_species_ids.map do |sid|
          occurrence = @occurrences_summary[row].detect { |occ| occ && (occ.species_id.to_s == sid) }
          if occurrence
            found = density_map.assoc(occurrence)
            found ? found.last.round(1).to_s : '0'
          else
            '0'
          end
        end + [(sample_density || 0).to_s]

        assert_equal expected, @report.values[row]
      end
    end
  end
end
