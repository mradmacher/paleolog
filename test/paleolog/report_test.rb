# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Report do
  before do
    @section = Section.sham!
    @counting = Counting.sham!(project: @section.project)
    @samples = []
    [100, 200, 300].each do |depth|
      @samples << Sample.sham!(section: @section, bottom_depth: depth)
    end
    @groups = [Group.sham!, Group.sham!]

    @species = []
    @groups.each_with_index do |group, i|
      @species[i] = []
      4.times { @species[i] << Specimen.sham!(group: group) }
    end

    @occurrences = []
    #sample, rank, group, species
    [
      [0, 0, 0, 2], [0, 1, 0, 3], [0, 2, 1, 0],
      [1, 0, 0, 0], [1, 1, 0, 1], [1, 2, 0, 3], [1, 3, 0, 2], [1, 4, 1, 0],
      [2, 0, 0, 1], [2, 1, 0, 2], [2, 2, 1, 1], [2, 3, 1, 2]
    ].each do |value|
      @occurrences[value[0]] = [] if @occurrences[value[0]].nil?
      @occurrences[value[0]][value[1]] = Occurrence.sham!( counting: @counting, sample: @samples[value[0]],
        specimen: @species[value[2]][value[3]], rank: value[1],
        status: (value[2] == 0 ? Occurrence::NORMAL : Occurrence::OUTSIDE_COUNT) )
    end
  end

  describe 'most abundant species' do
    setup do
      @samples_summary, @species_summary, @occurrences_summary = CountingSummary.new(@counting).summary(@section)
      @report = Report.build type: Report::QUANTITY, counting_id: @counting.id, section_id: @section.id,
        rows: { '0' => { 'sample_ids' => @samples_summary.map{ |s| s.id.to_s } } },
        columns: { '0' => { 'species_ids' => @species_summary.map{ |s| s.id.to_s }, 'merge' => 'most_abundant', 'header' => 'Most Abundant' } }
      @report.generate
    end

    should 'generate proper values' do
      expected = []
      @occurrences_summary.each_with_index do |row, i|
        expected[i] = row.max_by{ |o| o ? o.quantity : 0 }.quantity.to_s
      end
      expected.each_with_index do |v, i|
        assert_equal v, @report.values[i][0]
      end
    end
  end

  describe 'second most abundant species' do
    setup do
      @samples_summary, @species_summary, @occurrences_summary = CountingSummary.new(@counting).summary(@section)
      @report = Report.build type: Report::QUANTITY, counting_id: @counting.id, section_id: @section.id,
        rows: { '0' => { 'sample_ids' => @samples_summary.map{ |s| s.id.to_s } } },
        columns: { '0' => { 'species_ids' => @species_summary.map{ |s| s.id.to_s }, 'merge' => 'second_most_abundant', 'header' => 'Most Abundant' } }
      @report.generate
    end

    should 'generate proper values' do
      expected = []
      @occurrences_summary.each_with_index do |row, i|
        most_abundant = row.max_by{ |o| o ? o.quantity : 0 }
        second_most_abundant = row.reject { |v| v == most_abundant }.max_by{ |o| o ? o.quantity : 0 }
        expected[i] = second_most_abundant.quantity.to_s
      end
      expected.each_with_index do |v, i|
        assert_equal v, @report.values[i][0]
      end
    end
  end

  describe 'count' do
    setup do
      @samples_summary, @species_summary, @occurrences_summary = CountingSummary.new(@counting).summary(@section)
      @report = Report.build type: Report::QUANTITY, counting_id: @counting.id, section_id: @section.id,
        rows: { '0' => { 'sample_ids' => @samples_summary.map{ |s| s.id.to_s } } },
        columns: { '0' => { 'species_ids' => @species_summary.map{ |s| s.id.to_s }, 'merge' => 'count', 'header' => 'Species' } }
      @report.generate
    end

    should 'generate proper row headers' do
      assert_equal @samples_summary.map{ |s| s.name }, @report.row_headers
    end

    should 'generate proper column headers' do
      assert_equal 1, @report.column_headers.size
      assert_equal ['Species'], @report.column_headers
    end

    should 'generate proper values' do
      assert_equal '3', @report.values[0][0]
      assert_equal '5', @report.values[1][0]
      assert_equal '4', @report.values[2][0]
    end
  end

  describe 'computed' do
    setup do
      @samples_summary, @species_summary, @occurrences_summary = CountingSummary.new(@counting).summary(@section)
      @report = Report.build type: Report::QUANTITY, counting_id: @counting.id, section_id: @section.id,
        rows: { '0' => { 'sample_ids' => @samples_summary.map{ |s| s.id.to_s } } },
        columns: {
          '0' => { 'species_ids' => @species_summary.map{ |s| s.id.to_s }, 'merge' => 'count', 'header' => 'Species Count' },
          '1' => { 'species_ids' => @species_summary.map{ |s| s.id.to_s }, 'merge' => 'sum', 'header' => 'Species Sum' },
          '2' => { 'computed' => 'A/B', 'header' => 'Count/Sum' },
          '3' => { 'computed' => 'B/A', 'header' => 'Sum/Count' },
          '4' => { 'computed' => '(A - B) / (A + B)', 'header' => 'Ratio' }
        }
      @report.generate
    end

    should 'generate proper column headers' do
      assert_equal 5, @report.column_headers.size
      assert_equal ['Species Count', 'Species Sum', 'Count/Sum', 'Sum/Count', 'Ratio'], @report.column_headers
    end

    should 'generate proper values' do
      @occurrences_summary.each_with_index do |row, i|
        sum = row.inject(0) { |sum, v| sum + (v.nil?? 0 : v.quantity) }
        count = row.inject(0) { |sum, v| sum + (v.nil?? 0 : 1) }
        count_sum = (sum == 0 ? 0 : (count.to_f/sum.to_f).round(1))
        sum_count = (count == 0 ? 0 : (sum.to_f/count.to_f).round(1))
        ratio = (sum + count == 0 ? 0 : ((count - sum).to_f/(count + sum).to_f).round(1))
        expected = [count.to_s, sum.to_s, count_sum.to_s, sum_count.to_s, ratio.to_s]
        assert_equal expected, @report.values[i]
      end
    end
  end

  describe 'quantities' do
    setup do
      @samples_summary, @species_summary, @occurrences_summary = CountingSummary.new(@counting).summary(@section)
      @report = Report.build type: Report::QUANTITY, counting_id: @counting.id, section_id: @section.id,
        rows: { '0' => { 'sample_ids' => @samples_summary.map{ |s| s.id.to_s } } },
        columns: { '0' => { 'species_ids' => @species_summary.map{ |s| s.id.to_s } } }
      @report.generate
    end

    should 'generate proper row headers' do
      assert_equal @samples_summary.map{ |s| s.name }, @report.row_headers
    end

    should 'generate proper column headers' do
      assert_equal @species_summary.map{ |s| s.name }, @report.column_headers
    end

    should 'generate proper values' do
      @samples_summary.each_with_index do |sample, row|
        @occurrences_summary[row].each_with_index do |occurrence, column|
          expected = '0'
          unless occurrence.nil?
            expected = occurrence.quantity.to_s
            expected = expected + Occurrence::UNCERTAIN_SYMBOL if occurrence.uncertain?
          end
          assert_equal expected, @report.values[row][column]
        end
      end
    end
  end

  describe 'percentages' do
    setup do
      @samples_summary, @species_summary, @occurrences_summary = CountingSummary.new(@counting).summary(@section)
      @report = Report.build type: Report::QUANTITY, counting_id: @counting.id, section_id: @section.id,
        rows: { '0' => { 'sample_ids' => @samples_summary.map{ |s| s.id.to_s } } },
        columns: {
          '0' => { 'species_ids' => @species_summary.map{ |s| s.id.to_s },
            'percentages' => '1'  } }
      @report.generate
    end

    should 'generate proper row headers' do
      assert_equal @samples_summary.map{ |s| s.name }, @report.row_headers
    end

    should 'generate proper column headers' do
      assert_equal @species_summary.map{ |s| s.name }, @report.column_headers
    end

    should 'generate proper values' do
      @samples_summary.each_with_index do |sample, row|
        row_sum = @occurrences_summary[row].compact.inject(0) { |sum, occ| sum + occ.quantity }
        perc_sum = 0
        @occurrences_summary[row].each_with_index do |occurrence, column|
          expected = ''
          unless occurrence.nil?
            expected = (occurrence.quantity.to_f/row_sum * 100).round(2).to_s
          end
          perc_sum += @report.values[row][column].to_f
          assert_equal expected, @report.values[row][column]
        end
        assert_equal 100.0, perc_sum.round(1)
      end
    end
  end

  describe 'densities' do
    setup do
      @counting.group = @groups[0]
      @counting.marker = @species[1][0]
      @counting.marker_count = 30
      @counting.save
      @samples.each do |sample|
        sample.weight = 10.0
        sample.save
      end
      @samples_summary, @species_summary, @occurrences_summary = CountingSummary.new(@counting).summary(@section)
      @selected_species_ids = @species_summary.select{ |s| s.group == @counting.group }.map{ |s| s.id.to_s }
      @report = Report.build type: Report::DENSITY, counting_id: @counting.id, section_id: @section.id,
        rows: { '0' => { 'sample_ids' => @samples_summary.map{ |s| s.id.to_s } } },
        columns: { '0' => { 'species_ids' => @selected_species_ids },
          '1' => { 'species_ids' => @selected_species_ids, 'merge' => 'sum', 'header' => 'Density' } }
      @report.generate
    end

    describe 'generate proper row headers' do
      assert_equal @samples_summary.map{ |s| s.name }, @report.row_headers
    end

    describe 'generate proper column headers' do
      assert_equal [@species[0][2].name, @species[0][3].name, @species[0][0].name, @species[0][1].name, 'Density'],
        @report.column_headers
    end

    describe 'generate proper values' do
      species = [@species[0][2], @species[0][3], @species[0][0], @species[0][1]]
      density_map = CountingSummary.new(@counting).occurrence_density_map(@section)
      @samples_summary.each_with_index do |sample, row|
        species2occurrences = {}
        @occurrences_summary[row].each do |o|
          if o.present?
            species2occurrences[o.specimen_id.to_s] = o
          end
        end
        expected = @selected_species_ids.map do |sid|
          if species2occurrences[sid]
            if density_map[species2occurrences[sid]]
              density_map[species2occurrences[sid]].round(1).to_s
            else
              '0'
            end
          else
            '0'
          end
        end + [CountingSummary.new(@counting).group_per_gram(sample).round(1).to_s]
        assert_equal expected, @report.values[row]
      end
    end
  end
end
