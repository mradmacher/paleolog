# frozen_string_literal: true

require 'test_helper'

describe Paleolog::CountingSummary do
  before do
    @group_repo = Paleolog::Repo::Group.new
    @project_repo = Paleolog::Repo::Project.new
    @section_repo = Paleolog::Repo::Section.new
    @occurrence_repo = Paleolog::Repo::Occurrence.new
    @counting_repo = Paleolog::Repo::Counting.new
    @sample_repo = Paleolog::Repo::Sample.new

    @project = @project_repo.create(name: 'Test')
    @counting = @project_repo.add_counting(@project, name: 'Counting1')
    @section = @project_repo.add_section(@project, name: 'Section1')
    @marker_group = @group_repo.create(name: 'Marker Group')
    @marker = @group_repo.add_species(@marker_group, name: 'Marker')
  end

  describe 'group_per_gram' do
    before do
      @sample = @section_repo.add_sample(@section, name: 'Sample1')
      @group = @group_repo.create(name: 'Group1')
      other_group = @group_repo.create(name: 'Group2')

      species1 = @group_repo.add_species(@group, name: 'Species1')
      species2 = @group_repo.add_species(@group, name: 'Species2')
      species3 = @group_repo.add_species(other_group, name: 'Species3')
      species4 = @group_repo.add_species(other_group, name: 'Species4')
      @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: species1.id, quantity: 15)
      @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: species2.id, quantity: 42)
      @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: species3.id)
      @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: species4.id)
      @summary = Paleolog::CountingSummary.new
    end

    it 'returns nil when there is not enough properties' do
      @counting = @counting_repo.update(@counting.id, group_id: nil, marker_id: nil, marker_count: nil)
      @sample = @sample_repo.update(@sample.id, weight: nil)

      assert_nil @summary.group_per_gram(@counting, @sample)

      @counting = @counting_repo.update(@counting.id, group_id: @group.id)
      assert_nil @summary.group_per_gram(@counting, @sample)

      @counting = @counting_repo.update(@counting.id, marker_id: @marker.id)
      assert_nil @summary.group_per_gram(@counting, @sample)

      @counting = @counting_repo.update(@counting.id, marker_count: 37)
      assert_nil @summary.group_per_gram(@counting, @sample)

      @sample = @sample_repo.update(@sample.id, weight: 4.1234)
      assert_nil @summary.group_per_gram(@counting, @sample)

      @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: @marker.id, quantity: 20)

      @sample = @sample_repo.update(@sample.id, weight: 0)
      assert_nil @summary.group_per_gram(@counting, @sample)

      @sample = @sample_repo.update(@sample.id, weight: 4.1234)
      @counting = @counting_repo.update(@counting.id, marker_count: nil)
      assert_nil @summary.group_per_gram(@counting, @sample)
    end

    it 'gets proper result' do
      @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: @marker.id, quantity: 20)
      @counting = @counting_repo.update(@counting.id, group_id: @group.id, marker_id: @marker.id, marker_count: 37)
      @sample = @sample_repo.update(@sample.id, weight: 4.1234)
      result = @summary.group_per_gram(@counting, @sample)
      refute_nil result
      assert_equal 25.57, result.round(2)
    end
  end

  describe 'occurrence_density_map' do
    before do
      @sample = @section_repo.add_sample(@section, name: 'Sample1')
      @group = @group_repo.create(name: 'Group1')
      other_group = @group_repo.create(name: 'Group2')
      @species15 = @group_repo.add_species(@group, name: 'Species15')
      @species41 = @group_repo.add_species(@group, name: 'Species41')
      @species0 = @group_repo.add_species(@group, name: 'Species0')

      @occurrence15 = @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: @species15.id, quantity: 15)
      @occurrence41 = @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: @species41.id, quantity: 41)
      @occurrence0 = @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: @species0.id, quantity: nil)

      @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: @group_repo.add_species(other_group, name: 'Species111').id)
      @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: @group_repo.add_species(other_group, name: 'Species222').id)
      @summary = Paleolog::CountingSummary.new
    end

    it 'returns nil when there is not enough properties' do
      @counting = @counting_repo.update(@counting.id, group_id: nil, marker_id: nil, marker_count: nil)
      @sample = @sample_repo.update(@sample.id, weight: nil)
      assert @summary.occurrence_density_map(@counting, @section).empty?

      @counting = @counting_repo.update(@counting.id, group_id: @group.id)
      assert @summary.occurrence_density_map(@counting, @section).empty?

      @counting = @counting_repo.update(@counting.id, marker_id: @marker.id)
      assert @summary.occurrence_density_map(@counting, @section).empty?

      @counting = @counting_repo.update(@counting.id, marker_count: 37)
      assert @summary.occurrence_density_map(@counting, @section).empty?

      @sample = @sample_repo.update(@sample.id, weight: 4.1234)
      assert @summary.occurrence_density_map(@counting, @section).empty?

      @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: @marker.id, quantity: 20)

      @sample = @sample_repo.update(@sample.id, weight: 0)
      assert @summary.occurrence_density_map(@counting, @section).empty?

      @sample = @sample_repo.update(@sample.id, weight: 4.1234)
      @counting = @counting_repo.update(@counting.id, marker_count: nil)
      assert @summary.occurrence_density_map(@counting, @section).empty?
    end

    it 'returns proper result' do
      @counting = @counting_repo.update(@counting.id, group_id: @group.id, marker_id: @marker.id, marker_count: 37)
      @sample = @sample_repo.update(@sample.id, weight: 4.1234)

      @occurrence_repo.create(counting_id: @counting.id, sample_id: @sample.id, species_id: @marker.id, quantity: 20)

      density_map = @summary.occurrence_density_map(@counting, @section)
      refute density_map.empty?
      assert_equal 3, density_map.keys.size
      assert_equal 7, density_map[@occurrence15.id].round
      assert_equal 18, density_map[@occurrence41.id].round
      assert_equal 0, density_map[@occurrence0.id]
    end
  end

  describe 'for samples/species/occurrences' do
    before do
      @samples = []
      %w(100 200 300 400 500 600 700).each_with_index do |name, rank|
        @samples << @section_repo.add_sample(@section, name: name, rank: rank)
      end
      @group1 = @group_repo.create(name: 'Group1')
      @group2 = @group_repo.create(name: 'Group2')

      @species = []
      [@group1, @group2].each_with_index do |group, i|
        @species[i] = []
        4.times { @species[i] << @group_repo.add_species(group, name: "Species#{i}") }
      end

      @occurrences = []
      #sample, rank, group, species
      [
        [0, 0, 0, 2], [0, 1, 0, 3], [0, 2, 1, 0],
        [1, 0, 0, 1], [1, 1, 0, 2], [1, 2, 1, 1], [1, 3, 1, 2],
        [2, 0, 0, 0], [2, 1, 0, 1], [2, 2, 0, 3], [2, 3, 0, 2], [2, 4, 1, 0],
        [4, 0, 0, 2], [4, 1, 0, 0],
        [5, 0, 0, 0], [5, 1, 1, 2], [5, 2, 1, 1], [5, 3, 1, 0],
        [6, 0, 0, 2]
      ].each do |value|
        @occurrences[value[0]] = [] if @occurrences[value[0]].nil?
        @occurrences[value[0]][value[1]] = @occurrence_repo.create(
          counting_id: @counting.id,
          sample_id: @samples[value[0]].id,
          species_id: @species[value[2]][value[3]].id,
          rank: value[1],
          status: (value[2] == 0 ? Paleolog::CountingSummary::NORMAL : Paleolog::CountingSummary::OUTSIDE_COUNT)
        )
      end
      @summary = Paleolog::CountingSummary.new
    end

    describe 'summary' do
      it 'returns proper values for last occurrence' do
        expected_species = [@species[0][2], @species[0][0], @species[1][2], @species[1][1],
          @species[1][0], @species[0][1], @species[0][3]]
        expected_samples = [@samples[0], @samples[1], @samples[2], @samples[3], @samples[4], @samples[5], @samples[6]]
        expected_occurrences = [
          [@occurrences[0][0], nil, nil, nil, @occurrences[0][2], nil, @occurrences[0][1]],
          [@occurrences[1][1], nil, @occurrences[1][3], @occurrences[1][2], nil, @occurrences[1][0], nil],
          [@occurrences[2][3], @occurrences[2][0], nil, nil, @occurrences[2][4], @occurrences[2][1], @occurrences[2][2]],
          [nil, nil, nil, nil, nil, nil, nil],
          [@occurrences[4][0], @occurrences[4][1], nil, nil, nil, nil, nil],
          [nil, @occurrences[5][0], @occurrences[5][1], @occurrences[5][2], @occurrences[5][3], nil, nil],
          [@occurrences[6][0], nil, nil, nil, nil, nil, nil],
        ]
        samples, species, occurrences = @summary.summary(@counting, @section, occurrence: :last)
        assert_equal expected_species.map(&:id), species.map(&:id)
        assert_equal expected_samples.map(&:id), samples.map(&:id)

        assert_equal expected_occurrences.map { |row| row.map { |c| c&.id } }, occurrences.map { |row| row.map { |c| c&.id } }
      end

      it 'returns proper values for first occurrence' do
        expected_species = [@species[0][2], @species[0][3], @species[1][0], @species[0][1],
          @species[1][1], @species[1][2], @species[0][0]]
        expected_samples = [@samples[0], @samples[1], @samples[2], @samples[3], @samples[4], @samples[5], @samples[6]]
        expected_occurrences = [
          [@occurrences[0][0], @occurrences[0][1], @occurrences[0][2], nil, nil, nil, nil],
          [@occurrences[1][1], nil, nil, @occurrences[1][0], @occurrences[1][2], @occurrences[1][3], nil],
          [@occurrences[2][3], @occurrences[2][2], @occurrences[2][4], @occurrences[2][1], nil, nil, @occurrences[2][0]],
          [nil, nil, nil, nil, nil, nil, nil],
          [@occurrences[4][0], nil, nil, nil, nil, nil, @occurrences[4][1]],
          [nil, nil, @occurrences[5][3], nil, @occurrences[5][2], @occurrences[5][1], @occurrences[5][0]],
          [@occurrences[6][0], nil, nil, nil, nil, nil, nil]
        ]
        samples, species, occurrences = @summary.summary(@counting, @section, occurrence: :first)
        assert_equal expected_species.map(&:id), species.map(&:id)
        assert_equal expected_samples.map(&:id), samples.map(&:id)
        assert_equal expected_occurrences.map { |row| row.map { |c| c&.id } }, occurrences.map { |row| row.map { |c| c&.id } }
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
      3.times { |i| @groups << @group_repo.create(name: "Group#{i}") }
      80.times { |i| specimens << @group_repo.add_species(@groups.sample(1).first, name: "Species#{i}") }
      (1..10).to_a.each do |depth|
        species = specimens.sample( Random.new.rand( 1..specimens.size ) )
        (1..species.size).to_a.each do |rank|
          unless sample_depth.keys.include?( depth )
            sample_depth[depth] = @section_repo.add_sample(@section, name: depth, rank: depth)
            @samples << sample_depth[depth]
          end
          @occurrence_repo.create(counting_id: @counting.id, sample_id: sample_depth[depth].id, rank: rank, species_id: species[rank-1].id)
          @testing_examples << { sample: sample_depth[depth], rank: rank, species: species[rank-1] }
        end
      end
      @summary = Paleolog::CountingSummary.new
    end

    it 'returns ordered specimens' do
      sorted = @testing_examples.sort do |a, b|
        a[:sample].rank == b[:sample].rank ? a[:rank] <=> b[:rank] : a[:sample].rank <=> b[:sample].rank
      end
      expected_specimen_ids = sorted.map { |v| v[:species].id }.uniq

      received_specimens = @summary.specimens_by_occurrence_for_section(@counting, @section)
      assert_equal expected_specimen_ids.size, received_specimens.size
      assert_equal expected_specimen_ids, received_specimens.map{ |s| s.id }
    end

    it 'returns specimens in sample' do
      selected_samples = @samples.sample( Random.new.rand( 1..@samples.size) )
      selected_samples = selected_samples.sort{ |a, b| a.rank <=> b.rank }
      sorted = @testing_examples.reject{ |t| !selected_samples.include?( t[:sample] ) }.sort{ |a, b|
        a[:sample].rank == b[:sample].rank ? a[:rank] <=> b[:rank] : a[:sample].rank <=> b[:sample].rank }
      expected_specimen_ids = sorted.map{ |v| v[:species].id }.uniq

      received_specimens = @summary.specimens_by_occurrence(@counting, selected_samples)
      assert_equal expected_specimen_ids.size, received_specimens.size
      assert_equal expected_specimen_ids, received_specimens.map{ |s| s.id }
    end
  end

  describe 'availabe_species_ids' do
    it 'returns not used species ids in given sample' do
      group = @group_repo.create(name: 'TestGroup')
      species1 = @group_repo.add_species(group, name: 'Species1')
      species2 = @group_repo.add_species(group, name: 'Species2')
      species3 = @group_repo.add_species(group, name: 'Species3')
      other_species = @group_repo.add_species(@group_repo.create(name: 'Other TestGroup'), name: 'Other Species')
      sample = @section_repo.add_sample(@section, name: 'Sample1')
      @occurrence_repo.create(counting_id: @counting.id, sample_id: sample.id, species_id: species1.id)
      @occurrence_repo.create(counting_id: @counting.id, sample_id: sample.id, species_id: species3.id)

      assert_equal [species2.id], Paleolog::CountingSummary.new.available_species_ids(@counting, sample, group)
    end

    it 'returns all species ids for other sample' do
      group = @group_repo.create(name: 'TestGroup')
      species1 = @group_repo.add_species(group, name: 'Species1')
      species2 = @group_repo.add_species(group, name: 'Species2')
      species3 = @group_repo.add_species(group, name: 'Species3')
      other_species = @group_repo.add_species(@group_repo.create(name: 'Other TestGroup'), name: 'Other Species')
      sample = @section_repo.add_sample(@section, name: 'Sample1')
      other_sample = @section_repo.add_sample(@section, name: 'Sample2')
      @occurrence_repo.create(counting_id: @counting.id, sample_id: sample.id, species_id: species1.id)
      @occurrence_repo.create(counting_id: @counting.id, sample_id: sample.id, species_id: species3.id)

      tested = Paleolog::CountingSummary.new.available_species_ids(@counting, other_sample, group)
      assert_equal 3, tested.size
      assert tested.include? species1.id
      assert tested.include? species2.id
      assert tested.include? species3.id
    end
  end
end
