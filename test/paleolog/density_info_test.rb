# frozen_string_literal: true

require 'test_helper'

describe Paleolog::DensityInfo do
  before do
    @project = Paleolog::Project.new(name: 'Test')
    @section = Paleolog::Section.new(name: 'Section1', project: @project)
    @marker_group = Paleolog::Group.new(name: 'Marker Group')
    @marker = Paleolog::Species.new(name: 'Marker', group: @marker_group)
    @counted_group = Paleolog::Group.new(name: 'Group1')
    @other_group = Paleolog::Group.new(name: 'Group2')
    @marker_quantity = 37
    @counting = Paleolog::Counting.new(name: 'Counting1', project: @project, group: @counted_group, marker: @marker,
                                       marker_count: @marker_quantity,)
    @subject = Paleolog::DensityInfo.new
  end

  describe 'group_density' do
    before do
      @species1 = Paleolog::Species.new(name: 'Species1', group: @counted_group)
      @species2 = Paleolog::Species.new(name: 'Species2', group: @counted_group)
      @species3 = Paleolog::Species.new(name: 'Species3', group: @other_group)
      @species4 = Paleolog::Species.new(name: 'Species4', group: @other_group)
    end

    it 'gets proper result' do
      sample = Paleolog::Sample.new(
        name: 'Sample1', section: @section, weight: 4.1234, marker_quantity: @marker_quantity,
      )

      occurrences = []
      occurrences << Paleolog::Occurrence.new(
        counting: @counting,
        sample: sample,
        species: @species1,
        quantity: 15,
        status: Paleolog::Occurrence::NORMAL,
      )
      occurrences << Paleolog::Occurrence.new(
        counting: @counting,
        sample: sample,
        species: @species2,
        quantity: 42,
        status: Paleolog::Occurrence::NORMAL,
      )
      occurrences << Paleolog::Occurrence.new(
        counting: @counting,
        sample: sample,
        species: @species3,
        quantity: nil,
        status: Paleolog::Occurrence::OUTSIDE_COUNT,
      )
      occurrences << Paleolog::Occurrence.new(
        counting: @counting,
        sample: sample,
        species: @species4,
        quantity: nil,
        status: Paleolog::Occurrence::OUTSIDE_COUNT,
      )
      occurrences << Paleolog::Occurrence.new(
        counting: @counting,
        sample: sample,
        species: @marker,
        quantity: 20,
        status: Paleolog::Occurrence::MARKER,
      )

      result = @subject.group_density(occurrences, sample)

      refute_nil result
      assert_in_delta(25.57, result.round(2))
    end
  end

  describe '#occurrence_density_map' do
    before do
      @sample = Paleolog::Sample.new(
        name: 'Sample1',
        section: @section,
        weight: 4.1234,
        marker_quantity: @marker_quantity,
      )
      @samples = [@sample]
      @species15 = Paleolog::Species.new(name: 'Species15', group: @counted_group)
      @species41 = Paleolog::Species.new(name: 'Species41', group: @counted_group)
      @species0 = Paleolog::Species.new(name: 'Species0', group: @counted_group)

      @occurrences = []
      @occurrences << @occurrence15 = Paleolog::Occurrence.new(
        counting: @counting,
        sample: @sample,
        species: @species15,
        quantity: 15,
        status: Paleolog::Occurrence::NORMAL,
      )
      @occurrences << @occurrence41 = Paleolog::Occurrence.new(
        counting: @counting,
        sample: @sample,
        species: @species41,
        quantity: 41,
        status: Paleolog::Occurrence::NORMAL,
      )
      @occurrences << @occurrence0 = Paleolog::Occurrence.new(
        counting: @counting,
        sample: @sample,
        species: @species0,
        quantity: nil,
        status: Paleolog::Occurrence::NORMAL,
      )

      @occurrences << @occurrence111 = Paleolog::Occurrence.new(
        counting: @counting,
        sample: @sample,
        species: Paleolog::Species.new(name: 'Species111', group: @other_group),
        quantity: 15,
        status: Paleolog::Occurrence::OUTSIDE_COUNT,
      )
      @occurrences << @occurrence222 = Paleolog::Occurrence.new(
        counting: @counting,
        sample: @sample,
        species: Paleolog::Species.new(name: 'Species222', group: @other_group),
        quantity: 41,
        status: Paleolog::Occurrence::OUTSIDE_COUNT,
      )
    end

    it 'returns proper result' do
      @occurrences << @marker_occurrence = Paleolog::Occurrence.new(
        counting: @counting,
        sample: @sample,
        species: @marker,
        quantity: 20,
        status: Paleolog::Occurrence::MARKER,
      )

      result = @subject.occurrence_density_map(@occurrences, @samples)

      refute_empty result
      assert_equal 6, result.size
      assert_equal 7, result.assoc(@occurrence15).last.round
      assert_equal 18, result.assoc(@occurrence41).last.round
      assert_equal 0, result.assoc(@occurrence0).last
      assert_equal 7, result.assoc(@occurrence111).last.round
      assert_equal 18, result.assoc(@occurrence222).last.round
      assert_equal 9, result.assoc(@marker_occurrence).last.round
    end
  end
end
