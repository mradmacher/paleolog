# frozen_string_literal: true

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
