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
    @subject = Paleolog::DensityInfo.new(counted_group: @counted_group, marker: @marker,
                                         marker_quantity: @marker_quantity,)
  end

  describe 'group_density' do
    before do
      @species1 = Paleolog::Species.new(name: 'Species1', group: @counted_group)
      @species2 = Paleolog::Species.new(name: 'Species2', group: @counted_group)
      @species3 = Paleolog::Species.new(name: 'Species3', group: @other_group)
      @species4 = Paleolog::Species.new(name: 'Species4', group: @other_group)
    end

    it 'gets proper result' do
      sample = Paleolog::Sample.new(name: 'Sample1', section: @section, weight: 4.1234)

      occurrences = []
      occurrences << Paleolog::Occurrence.new(counting: @counting, sample: sample, species: @species1, quantity: 15)
      occurrences << Paleolog::Occurrence.new(counting: @counting, sample: sample, species: @species2, quantity: 42)
      occurrences << Paleolog::Occurrence.new(counting: @counting, sample: sample, species: @species3, quantity: nil)
      occurrences << Paleolog::Occurrence.new(counting: @counting, sample: sample, species: @species4, quantity: nil)
      occurrences << Paleolog::Occurrence.new(counting: @counting, sample: sample, species: @marker, quantity: 20)

      result = @subject.group_density(occurrences, sample)
      refute_nil result
      assert_equal 25.57, result.round(2)
    end
  end

  describe '#occurrence_density_map' do
    before do
      @sample = Paleolog::Sample.new(name: 'Sample1', section: @section, weight: 4.1234)
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
      )
      @occurrences << @occurrence41 = Paleolog::Occurrence.new(
        counting: @counting,
        sample: @sample,
        species: @species41,
        quantity: 41,
      )
      @occurrences << @occurrence0 = Paleolog::Occurrence.new(
        counting: @counting,
        sample: @sample,
        species: @species0,
        quantity: nil,
      )

      @occurrences << Paleolog::Occurrence.new(
        counting: @counting,
        sample: @sample,
        species: Paleolog::Species.new(name: 'Species111', group: @other_group),
      )
      @occurrences << Paleolog::Occurrence.new(
        counting: @counting,
        sample: @sample,
        species: Paleolog::Species.new(name: 'Species222', group: @other_group),
      )
    end

    it 'returns proper result' do
      @occurrences << Paleolog::Occurrence.new(counting: @counting, sample: @sample, species: @marker, quantity: 20)

      result = @subject.occurrence_density_map(@occurrences, @samples)
      refute result.empty?
      assert_equal 3, result.size
      assert_equal 7, result.assoc(@occurrence15).last.round
      assert_equal 18, result.assoc(@occurrence41).last.round
      assert_equal 0, result.assoc(@occurrence0).last
    end
  end
end

__END__

require 'test_helper'

describe Paleolog::Contract::Density do
  before do
    @project = Paleolog::Project.new(name: 'Test')
    @counting = Paleolog::Counting.new(name: 'Counting1', project: @project)
    @section = Paleolog::Section.new(name: 'Section1', project: @project)
    @sample = Paleolog::Sample.new(name: 'Sample1', section: @section)
    @counting = Paleolog::Counting.new(name: 'Counting1', project: @project)
    @group = Paleolog::Group.new(name: 'Group1')

    @marker_species = Paleolog::Species.new(name: 'Marker', group: Paleolog::Group.new(name: 'Marker Group'))
    @species = Paleolog::Species.new(name: 'Species', group: @group)

    @occurrence = Paleolog::Occurrence.new(counting: @counting, sample: @sample, species: @species, quantity: 20)
    @marker_occurrence = Paleolog::Occurrence.new(counting: @counting, sample: @sample, species: @marker_species,
                                                  quantity: 20,)
    @marker_0_occurrence = Paleolog::Occurrence.new(counting: @counting, sample: @sample, species: @marker_species,
                                                    quantity: 0,)
    @marker_nil_occurrence = Paleolog::Occurrence.new(counting: @counting, sample: @sample, species: @marker_species,
                                                      quantity: nil,)

    @counted_group = @group
    @marker = @marker_species
    @marker_quantity = 37
    @sample_weight = 4.1234
    @occurrences = [@occurrence, @marker_occurrence]

    @contract = Paleolog::Contract::Density.new
  end

  it 'requires sample weight' do
    @sample_weight = nil
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:sample_weight)
    assert result.errors[:sample_weight].include?('must be filled')
  end

  it 'requires sample weight greater than 0' do
    @sample_weight = 0
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:sample_weight)
    assert result.errors[:sample_weight].include?('must be greater than 0')
  end

  it 'requires positive sample weight' do
    @sample_weight = -1
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:sample_weight)
    assert result.errors[:sample_weight].include?('must be greater than 0')
  end

  it 'requires counted group' do
    @counted_group = nil
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:counted_group)
    assert result.errors[:counted_group].include?('must be filled')
  end

  it 'requires marker group' do
    @marker = nil
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:marker)
    assert result.errors[:marker].include?('must be filled')
  end

  it 'requires marker quantity' do
    @marker_quantity = nil
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:marker_quantity)
    assert result.errors[:marker_quantity].include?('must be filled')
  end

  it 'requires positive marker count' do
    @marker_quantity = 0
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:marker_quantity)
    assert result.errors[:marker_quantity].include?('must be greater than 0')
  end

  it 'requires occurrences' do
    @occurrences = nil
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:occurrences)
    assert result.errors[:occurrences].include?('must be filled')

    @occurrences = []
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:occurrences)
    assert result.errors[:occurrences].include?('must be filled')
  end

  it 'requires marker occurrences' do
    @occurrences = [@occurrence]
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:occurrences)
    assert result.errors[:occurrences].include?('must include marker')
  end

  it 'requires marker count' do
    @occurrences = [@marker_nil_occurrence]
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:occurrences)
    assert result.errors[:occurrences].include?('must include marker')
  end

  it 'requires positive marker count' do
    @occurrences = [@marker_0_occurrence]
    result = @contract.call(
      counted_group: @counted_group,
      marker: @marker,
      marker_quantity: @marker_quantity,
      sample_weight: @sample_weight,
      occurrences: @occurrences,
    )
    assert result.error?(:occurrences)
    assert result.errors[:occurrences].include?('must include marker')
  end
end
