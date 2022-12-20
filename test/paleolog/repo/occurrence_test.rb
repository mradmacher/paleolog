# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Occurrence do
  let(:repo) { Paleolog::Repo::Occurrence }
  let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some project')) }

  after do
    repo.delete_all
  end

  describe '#find_in_project' do
    let(:group) { Paleolog::Repo::Group.create(name: 'Some group') }
    let(:species) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Some species', group: group)) }
    let(:section) { Paleolog::Repo::Section.create(name: 'Some section', project_id: project.id) }
    let(:counting) { Paleolog::Repo.save(Paleolog::Counting.new(name: 'Some counting', project: project)) }
    let(:sample) { Paleolog::Repo.save(Paleolog::Sample.new(name: 'Some sample', section: section)) }
    let(:occurrence) do
      repo.create(
        rank: 1,
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample.id,
      )
    end

    it 'returns occurrence if it is within the project' do
      result = repo.find_in_project(occurrence.id, project.id)
      assert result
      assert_equal occurrence.id, result.id
    end

    it 'returns nil if it is not within the project' do
      other_project = Paleolog::Repo.save(Paleolog::Project.new(name: 'Other project'))

      result = repo.find_in_project(occurrence.id, other_project.id)
      assert_nil result
    end
  end

  describe '#all_for_sample' do
    let(:group) { Paleolog::Repo::Group.create(name: 'Some group') }
    let(:section) { Paleolog::Repo::Section.create(name: 'Some section', project_id: project.id) }
    let(:counting) { Paleolog::Repo.save(Paleolog::Counting.new(name: 'Some counting', project: project)) }
    let(:sample) { Paleolog::Repo.save(Paleolog::Sample.new(name: 'Some sample', section: section)) }
    let(:species) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Some species', group: group)) }

    it 'returns all occurrences for given sample and counting' do
      other_counting = Paleolog::Repo.save(Paleolog::Counting.new(name: 'Other counting', project: project))
      other_sample = Paleolog::Repo.save(Paleolog::Sample.new(name: 'Other sample', section: section))
      other_species = Paleolog::Repo.save(Paleolog::Species.new(name: 'Other species', group: group))

      occurrence1 = repo.create(
        rank: 1,
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample.id,
      )
      repo.create(
        rank: 2,
        species_id: species.id,
        counting_id: counting.id,
        sample_id: other_sample.id,
      )
      repo.create(
        rank: 3,
        species_id: species.id,
        counting_id: other_counting.id,
        sample_id: sample.id,
      )
      occurrence4 = repo.create(
        rank: 4,
        species_id: other_species.id,
        counting_id: counting.id,
        sample_id: sample.id,
      )
      repo.create(
        rank: 5,
        species_id: other_species.id,
        counting_id: other_counting.id,
        sample_id: sample.id,
      )
      repo.create(
        rank: 6,
        species_id: other_species.id,
        counting_id: counting.id,
        sample_id: other_sample.id,
      )

      result = repo.all_for_sample(counting.id, sample.id)
      assert_equal([occurrence1.id, occurrence4.id].sort, result.map(&:id).sort)
    end

    it 'loads species' do
      repo.create(
        rank: 1,
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample.id,
      )
      result = repo.all_for_sample(counting.id, sample.id)
      assert_equal(species.id, result.first.species.id)
    end

    it 'loads sample' do
      repo.create(
        rank: 1,
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample.id,
      )
      result = repo.all_for_sample(counting.id, sample.id)
      assert_equal(sample.id, result.first.sample.id)
    end
  end

  describe '#all_for_section' do
    let(:group) { Paleolog::Repo::Group.create(name: 'Some group') }
    let(:section) { Paleolog::Repo::Section.create(name: 'Some section', project_id: project.id) }
    let(:counting) { Paleolog::Repo.save(Paleolog::Counting.new(name: 'Some counting', project: project)) }
    let(:sample1) { Paleolog::Repo.save(Paleolog::Sample.new(name: 'Sample1', section: section)) }
    let(:sample2) { Paleolog::Repo.save(Paleolog::Sample.new(name: 'Sample2', section: section)) }
    let(:species) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Some species', group: group)) }

    it 'returns all occurrences for given sample and counting' do
      other_counting = Paleolog::Repo.save(Paleolog::Counting.new(name: 'Other counting', project: project))
      other_section = Paleolog::Repo.save(Paleolog::Section.new(name: 'Other section', project: project))
      other_sample = Paleolog::Repo.save(Paleolog::Sample.new(name: 'Other sample', section: other_section))

      occurrence1 = repo.create(
        rank: 1,
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample1.id,
      )
      occurrence2 = repo.create(
        rank: 2,
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample2.id,
      )
      repo.create(
        rank: 3,
        species_id: species.id,
        counting_id: counting.id,
        sample_id: other_sample.id,
      )
      repo.create(
        rank: 4,
        species_id: species.id,
        counting_id: other_counting.id,
        sample_id: sample1.id,
      )

      result = repo.all_for_section(counting, section)
      assert_equal([occurrence1.id, occurrence2.id].sort, result.map(&:id).sort)
    end

    it 'loads species' do
      repo.create(
        rank: 1,
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample1.id,
      )
      result = repo.all_for_section(counting, section)
      assert_equal(species.id, result.first.species.id)
    end

    it 'loads sample' do
      repo.create(
        rank: 1,
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample1.id,
      )
      result = repo.all_for_section(counting, section)
      assert_equal(sample1.id, result.first.sample.id)
    end
  end

  describe 'validations' do
    before do
      section = Paleolog::Repo::Section.create(name: 'Some section', project_id: project.id)
      @sample = Paleolog::Repo::Sample.create(name: 'Some sample', section_id: section.id)
      @counting = Paleolog::Repo::Counting.create(name: 'Some counting', project_id: project.id)
      group = Paleolog::Repo::Group.create(name: 'Some group')
      @species = Paleolog::Repo::Species.create(name: 'Some species', group_id: group.id)
      @other_counting = Paleolog::Repo::Counting.create(name: 'Other counting', project_id: project.id)
      @other_sample = Paleolog::Repo::Sample.create(name: 'Other sample', section_id: section.id)
    end

    after do
      Paleolog::Repo::Group.delete_all
      Paleolog::Repo::Section.delete_all
      Paleolog::Repo::Sample.delete_all
      Paleolog::Repo::Counting.delete_all
      Paleolog::Repo::Species.delete_all
    end

    describe '#rank_exists_within_counting_and_sample?' do
      it 'checks rank uniqueness within counting and sample scope' do
        repo.create(
          rank: 1,
          species_id: @species.id,
          counting_id: @counting.id,
          sample_id: @sample.id,
        )

        assert(repo.rank_exists_within_counting_and_sample?(1, @counting.id, @sample.id))
        refute(repo.rank_exists_within_counting_and_sample?(2, @counting.id, @sample.id))
        refute(repo.rank_exists_within_counting_and_sample?(1, @other_counting.id, @sample.id))
        refute(repo.rank_exists_within_counting_and_sample?(1, @counting.id, @other_sample.id))
        refute(repo.rank_exists_within_counting_and_sample?(1, @other_counting.id, @other_sample.id))
      end
    end

    describe '#species_exists_within_counting_and_sample?' do
      it 'checks rank uniqueness within counting and sample scope' do
        repo.create(
          species_id: @species.id,
          counting_id: @counting.id,
          sample_id: @sample.id,
        )

        assert(repo.species_exists_within_counting_and_sample?(@species.id, @counting.id, @sample.id))
        refute(repo.species_exists_within_counting_and_sample?(2, @counting.id, @sample.id))
        refute(repo.species_exists_within_counting_and_sample?(@species.id, @other_counting.id, @sample.id))
        refute(repo.species_exists_within_counting_and_sample?(@species.id, @counting.id, @other_sample.id))
        refute(repo.species_exists_within_counting_and_sample?(@species.id, @other_counting.id, @other_sample.id))
      end
    end

    describe '#availabe_species_ids' do
      it 'returns not used species ids in given sample' do
        group = Paleolog::Repo.save(Paleolog::Group.new(name: 'TestGroup'))
        species1 = Paleolog::Repo.save(Paleolog::Species.new(group: group, name: 'Species1'))
        species2 = Paleolog::Repo.save(Paleolog::Species.new(group: group, name: 'Species2'))
        species3 = Paleolog::Repo.save(Paleolog::Species.new(group: group, name: 'Species3'))
        sample = Paleolog::Repo.save(Paleolog::Sample.new(section: @section, name: 'Sample1'))
        Paleolog::Repo.save(Paleolog::Occurrence.new(counting: @counting, sample: sample, species: species1))
        Paleolog::Repo.save(Paleolog::Occurrence.new(counting: @counting, sample: sample, species: species3))

        assert_equal [species2.id], repo.available_species_ids(@counting, sample, group)
      end

      it 'returns all species ids for other sample' do
        group = Paleolog::Repo.save(Paleolog::Group.new(name: 'TestGroup'))
        species1 = Paleolog::Repo.save(Paleolog::Species.new(group: group, name: 'Species1'))
        species2 = Paleolog::Repo.save(Paleolog::Species.new(group: group, name: 'Species2'))
        species3 = Paleolog::Repo.save(Paleolog::Species.new(group: group, name: 'Species3'))
        sample = Paleolog::Repo.save(Paleolog::Sample.new(section: @section, name: 'Sample1'))
        other_sample = Paleolog::Repo.save(Paleolog::Sample.new(section: @section, name: 'Sample2'))
        Paleolog::Repo.save(Paleolog::Occurrence.new(counting: @counting, sample: sample, species: species1))
        Paleolog::Repo.save(Paleolog::Occurrence.new(counting: @counting, sample: sample, species: species3))

        tested = repo.available_species_ids(@counting, other_sample, group)
        assert_equal 3, tested.size
        assert tested.include? species1.id
        assert tested.include? species2.id
        assert tested.include? species3.id
      end
    end
  end
end
