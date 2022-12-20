# frozen_string_literal: true

require 'test_helper'

describe Paleolog::CountingSummary do
  before do
    @project = Paleolog::Project.new(name: 'Test')
    @counting = Paleolog::Counting.new(name: 'Counting1', project: @project)
    @section = Paleolog::Section.new(name: 'Section1', project: @project)
    @marker_group = Paleolog::Group.new(name: 'Marker Group')
    @marker = Paleolog::Species.new(name: 'Marker', group: @marker_group)
  end

  describe 'for samples/species/occurrences' do
    before do
      @samples = []
      %w[100 200 300 400 500 600 700].each_with_index do |name, rank|
        @samples << Paleolog::Sample.new(name: name, rank: rank, section: @section)
      end
      @group1 = Paleolog::Group.new(name: 'Group1')
      @group2 = Paleolog::Group.new(name: 'Group2')

      @species = []
      [@group1, @group2].each_with_index do |group, i|
        @species[i] = []
        4.times { |j| @species[i] << Paleolog::Species.new(name: "Species#{i}-#{j}", group: group) }
      end

      @occurrences = []
      # sample, rank, group, species
      [
        [0, 0, 0, 2], [0, 1, 0, 3], [0, 2, 1, 0],
        [1, 0, 0, 1], [1, 1, 0, 2], [1, 2, 1, 1], [1, 3, 1, 2],
        [2, 0, 0, 0], [2, 1, 0, 1], [2, 2, 0, 3], [2, 3, 0, 2], [2, 4, 1, 0],
        [4, 0, 0, 2], [4, 1, 0, 0],
        [5, 0, 0, 0], [5, 1, 1, 2], [5, 2, 1, 1], [5, 3, 1, 0],
        [6, 0, 0, 2]
      ].each do |value|
        @occurrences[value[0]] = [] if @occurrences[value[0]].nil?
        @occurrences[value[0]][value[1]] = Paleolog::Occurrence.new(
          counting: @counting,
          sample: @samples[value[0]],
          species: @species[value[2]][value[3]],
          rank: value[1],
          status: ((value[2]).zero? ? Paleolog::Occurrence::NORMAL : Paleolog::Occurrence::OUTSIDE_COUNT),
        )
      end
    end

    describe 'summary' do
      it 'returns proper values for last occurrence' do
        expected_species = [@species[0][2], @species[0][0], @species[1][2], @species[1][1],
                            @species[1][0], @species[0][1], @species[0][3]]
        expected_samples = [@samples[0], @samples[1], @samples[2], @samples[3], @samples[4], @samples[5], @samples[6]]
        expected_occurrences = [
          [@occurrences[0][0], nil, nil, nil, @occurrences[0][2], nil, @occurrences[0][1]],
          [@occurrences[1][1], nil, @occurrences[1][3], @occurrences[1][2], nil, @occurrences[1][0], nil],
          [@occurrences[2][3], @occurrences[2][0], nil, nil, @occurrences[2][4], @occurrences[2][1],
           @occurrences[2][2]],
          [nil, nil, nil, nil, nil, nil, nil],
          [@occurrences[4][0], @occurrences[4][1], nil, nil, nil, nil, nil],
          [nil, @occurrences[5][0], @occurrences[5][1], @occurrences[5][2], @occurrences[5][3], nil, nil],
          [@occurrences[6][0], nil, nil, nil, nil, nil, nil]
        ]
        samples, species, occurrences =
          Paleolog::CountingSummary.new(@occurrences.flatten.compact).summary(@samples, occurrence: :last)
        assert_equal expected_samples.size, samples.size
        assert_equal expected_samples, samples
        assert_equal expected_species.size, species.size
        assert_equal expected_species, species

        assert_equal(
          expected_occurrences.map do |row|
            row.map do |col|
              col ? "#{col.species.name}-#{col.sample.name}-#{col.counting.name}" : nil
            end
          end,
          occurrences.map do |row|
            row.map do |col|
              col ? "#{col.species.name}-#{col.sample.name}-#{col.counting.name}" : nil
            end
          end,
        )
      end

      it 'returns proper values for first occurrence' do
        expected_species = [@species[0][2], @species[0][3], @species[1][0], @species[0][1],
                            @species[1][1], @species[1][2], @species[0][0]]
        expected_samples = [@samples[0], @samples[1], @samples[2], @samples[3], @samples[4], @samples[5], @samples[6]]
        expected_occurrences = [
          [@occurrences[0][0], @occurrences[0][1], @occurrences[0][2], nil, nil, nil, nil],
          [@occurrences[1][1], nil, nil, @occurrences[1][0], @occurrences[1][2], @occurrences[1][3], nil],
          [@occurrences[2][3], @occurrences[2][2], @occurrences[2][4], @occurrences[2][1], nil, nil,
           @occurrences[2][0]],
          [nil, nil, nil, nil, nil, nil, nil],
          [@occurrences[4][0], nil, nil, nil, nil, nil, @occurrences[4][1]],
          [nil, nil, @occurrences[5][3], nil, @occurrences[5][2], @occurrences[5][1], @occurrences[5][0]],
          [@occurrences[6][0], nil, nil, nil, nil, nil, nil]
        ]
        samples, species, occurrences =
          Paleolog::CountingSummary.new(@occurrences.flatten.compact).summary(@samples, occurrence: :first)
        assert_equal expected_samples.size, samples.size
        assert_equal expected_samples, samples
        assert_equal expected_species.size, species.size
        assert_equal expected_species, species
        assert_equal(
          expected_occurrences.map { |row| row.map { |c| c&.id } },
          occurrences.map { |row| row.map { |c| c&.id } },
        )
      end
    end
  end

  describe 'specimens_by_occurrence' do
    before do
      sample_depth = {}
      @samples = []
      specimens = []
      @groups = []
      @testing_examples = []
      @occurrences = []
      3.times { |i| @groups << Paleolog::Group.new(name: "Group#{i}") }
      80.times { |i| specimens << Paleolog::Species.new(group: @groups.sample(1).first, name: "Species#{i}") }
      (1..10).to_a.each do |depth|
        species = specimens.sample(Random.new.rand(1..specimens.size))
        (1..species.size).to_a.each do |rank|
          unless sample_depth.keys.include?(depth)
            sample_depth[depth] = Paleolog::Sample.new(section: @section, name: depth, rank: depth)
            @samples << sample_depth[depth]
          end
          @occurrences << Paleolog::Occurrence.new(
            counting: @counting,
            sample: sample_depth[depth],
            rank: rank,
            species: species[rank - 1],
          )
          @testing_examples << { sample: sample_depth[depth], rank: rank, species: species[rank - 1] }
        end
      end
    end

    it 'returns ordered specimens' do
      sorted = @testing_examples.sort do |a, b|
        a[:sample].rank == b[:sample].rank ? a[:rank] <=> b[:rank] : a[:sample].rank <=> b[:sample].rank
      end
      expected_specimens = sorted.map { |v| v[:species] }.uniq

      received_specimens = Paleolog::CountingSummary.new(@occurrences).specimens_by_occurrence(@samples)
      assert_equal expected_specimens.size, received_specimens.size
      assert_equal expected_specimens, received_specimens
    end

    it 'returns specimens in sample' do
      selected_samples = @samples.sample(Random.new.rand(1..@samples.size))
      selected_samples = selected_samples.sort { |a, b| a.rank <=> b.rank }
      sorted = @testing_examples.select { |t| selected_samples.include?(t[:sample]) }.sort do |a, b|
        a[:sample].rank == b[:sample].rank ? a[:rank] <=> b[:rank] : a[:sample].rank <=> b[:sample].rank
      end
      expected_specimens = sorted.map { |v| v[:species] }.uniq

      received_specimens = Paleolog::CountingSummary.new(
        @occurrences.select { |occ| selected_samples.include?(occ.sample) },
      ).specimens_by_occurrence(selected_samples)
      assert_equal expected_specimens.size, received_specimens.size
      assert_equal expected_specimens, received_specimens
    end
  end
end
