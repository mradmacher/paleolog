# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Occurrence do
  let(:repo) { Paleolog::Repo::Occurrence }
  let(:project_id) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Some project')) }
  let(:group_id) { Paleolog::Repo::Group.create(name: 'Some group') }
  let(:species_id) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Some species', group_id: group_id)) }
  let(:section_id) { Paleolog::Repo::Section.create(name: 'Some section', project_id: project_id) }
  let(:counting_id) { Paleolog::Repo.save(Paleolog::Counting.new(name: 'Some counting', project_id: project_id)) }
  let(:sample_id) { Paleolog::Repo.save(Paleolog::Sample.new(name: 'Some sample', section_id: section_id)) }

  after do
    repo.delete_all
    Paleolog::Repo.delete_all(Paleolog::Species)
    Paleolog::Repo.delete_all(Paleolog::Group)
    Paleolog::Repo.delete_all(Paleolog::Sample)
    Paleolog::Repo.delete_all(Paleolog::Section)
    Paleolog::Repo.delete_all(Paleolog::Counting)
    Paleolog::Repo.delete_all(Paleolog::Project)
  end

  describe '#find_in_project' do
    let(:occurrence_id) do
      repo.create(
        rank: 1,
        species_id: species_id,
        counting_id: counting_id,
        sample_id: sample_id,
      )
    end

    it 'returns occurrence if it is within the project' do
      result = repo.find_in_project(occurrence_id, project_id)
      assert result
      assert_equal occurrence_id, result.id
    end

    it 'returns nil if it is not within the project' do
      other_project_id = Paleolog::Repo.save(Paleolog::Project.new(name: 'Other project'))

      result = repo.find_in_project(occurrence_id, other_project_id)
      assert_nil result
    end
  end

  describe '#all_for_sample' do
    it 'returns all occurrences for given sample and counting' do
      other_counting_id = Paleolog::Repo.save(Paleolog::Counting.new(name: 'Other counting', project_id: project_id))
      other_sample_id = Paleolog::Repo.save(Paleolog::Sample.new(name: 'Other sample', section_id: section_id))
      other_species_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'Other species', group_id: group_id))

      occurrence1_id = repo.create(
        rank: 1,
        species_id: species_id,
        counting_id: counting_id,
        sample_id: sample_id,
      )
      repo.create(
        rank: 2,
        species_id: species_id,
        counting_id: counting_id,
        sample_id: other_sample_id,
      )
      repo.create(
        rank: 3,
        species_id: species_id,
        counting_id: other_counting_id,
        sample_id: sample_id,
      )
      occurrence4_id = repo.create(
        rank: 4,
        species_id: other_species_id,
        counting_id: counting_id,
        sample_id: sample_id,
      )
      repo.create(
        rank: 5,
        species_id: other_species_id,
        counting_id: other_counting_id,
        sample_id: sample_id,
      )
      repo.create(
        rank: 6,
        species_id: other_species_id,
        counting_id: counting_id,
        sample_id: other_sample_id,
      )

      result = repo.all_for_sample(counting_id, sample_id)
      assert_equal([occurrence1_id, occurrence4_id].sort, result.map(&:id).sort)
    end

    it 'loads species' do
      repo.create(
        rank: 1,
        species_id: species_id,
        counting_id: counting_id,
        sample_id: sample_id,
      )
      result = repo.all_for_sample(counting_id, sample_id)
      assert_equal(species_id, result.first.species.id)
    end

    it 'loads sample' do
      repo.create(
        rank: 1,
        species_id: species_id,
        counting_id: counting_id,
        sample_id: sample_id,
      )
      result = repo.all_for_sample(counting_id, sample_id)
      assert_equal(sample_id, result.first.sample.id)
    end
  end

  describe '#all_for_section' do
    let(:sample1_id) { Paleolog::Repo.save(Paleolog::Sample.new(name: 'Sample1', section_id: section_id)) }
    let(:sample2_id) { Paleolog::Repo.save(Paleolog::Sample.new(name: 'Sample2', section_id: section_id)) }

    it 'returns all occurrences for given sample and counting' do
      other_counting_id = Paleolog::Repo.save(Paleolog::Counting.new(name: 'Other counting', project_id: project_id))
      other_section_id = Paleolog::Repo.save(Paleolog::Section.new(name: 'Other section', project_id: project_id))
      other_sample_id = Paleolog::Repo.save(Paleolog::Sample.new(name: 'Other sample', section_id: other_section_id))

      occurrence1_id = repo.create(
        rank: 1,
        species_id: species_id,
        counting_id: counting_id,
        sample_id: sample1_id,
      )
      occurrence2_id  = repo.create(
        rank: 2,
        species_id: species_id,
        counting_id: counting_id,
        sample_id: sample2_id,
      )
      repo.create(
        rank: 3,
        species_id: species_id,
        counting_id: counting_id,
        sample_id: other_sample_id,
      )
      repo.create(
        rank: 4,
        species_id: species_id,
        counting_id: other_counting_id,
        sample_id: sample1_id,
      )

      result = repo.all_for_section(counting_id, section_id)
      assert_equal([occurrence1_id, occurrence2_id].sort, result.map(&:id).sort)
    end

    it 'loads species' do
      repo.create(
        rank: 1,
        species_id: species_id,
        counting_id: counting_id,
        sample_id: sample1_id,
      )
      result = repo.all_for_section(counting_id, section_id)
      assert_equal(species_id, result.first.species.id)
    end

    it 'loads sample' do
      repo.create(
        rank: 1,
        species_id: species_id,
        counting_id: counting_id,
        sample_id: sample1_id,
      )
      result = repo.all_for_section(counting_id, section_id)
      assert_equal(sample1_id, result.first.sample.id)
    end
  end

  describe 'validations' do
    let(:other_counting_id) { Paleolog::Repo::Counting.create(name: 'Other counting', project_id: project_id) }
    let(:other_sample_id) { Paleolog::Repo::Sample.create(name: 'Other sample', section_id: section_id) }

    describe '#rank_exists_within_counting_and_sample?' do
      it 'checks rank uniqueness within counting and sample scope' do
        repo.create(
          rank: 1,
          species_id: species_id,
          counting_id: counting_id,
          sample_id: sample_id,
        )

        assert(repo.rank_exists_within_counting_and_sample?(1, counting_id, sample_id))
        refute(repo.rank_exists_within_counting_and_sample?(2, counting_id, sample_id))
        refute(repo.rank_exists_within_counting_and_sample?(1, other_counting_id, sample_id))
        refute(repo.rank_exists_within_counting_and_sample?(1, counting_id, other_sample_id))
        refute(repo.rank_exists_within_counting_and_sample?(1, other_counting_id, other_sample_id))
      end
    end

    describe '#species_exists_within_counting_and_sample?' do
      it 'checks rank uniqueness within counting and sample scope' do
        repo.create(
          species_id: species_id,
          counting_id: counting_id,
          sample_id: sample_id,
        )

        assert(repo.species_exists_within_counting_and_sample?(species_id, counting_id, sample_id))
        refute(repo.species_exists_within_counting_and_sample?(2, counting_id, sample_id))
        refute(repo.species_exists_within_counting_and_sample?(species_id, other_counting_id, sample_id))
        refute(repo.species_exists_within_counting_and_sample?(species_id, counting_id, other_sample_id))
        refute(repo.species_exists_within_counting_and_sample?(species_id, other_counting_id, other_sample_id))
      end
    end

    describe '#availabe_species_ids' do
      it 'returns not used species ids in given sample' do
        species1_id = Paleolog::Repo.save(Paleolog::Species.new(group_id: group_id, name: 'Species1'))
        species2_id = Paleolog::Repo.save(Paleolog::Species.new(group_id: group_id, name: 'Species2'))
        species3_id = Paleolog::Repo.save(Paleolog::Species.new(group_id: group_id, name: 'Species3'))
        Paleolog::Repo.save(Paleolog::Occurrence.new(counting_id: counting_id, sample_id: sample_id, species_id: species1_id))
        Paleolog::Repo.save(Paleolog::Occurrence.new(counting_id: counting_id, sample_id: sample_id, species_id: species3_id))

        assert_equal [species2_id], repo.available_species_ids(counting_id, sample_id, group_id)
      end

      it 'returns all species ids for other sample' do
        species1_id = Paleolog::Repo.save(Paleolog::Species.new(group_id: group_id, name: 'Species1'))
        species2_id = Paleolog::Repo.save(Paleolog::Species.new(group_id: group_id, name: 'Species2'))
        species3_id = Paleolog::Repo.save(Paleolog::Species.new(group_id: group_id, name: 'Species3'))
        other_sample_id = Paleolog::Repo.save(Paleolog::Sample.new(section_id: section_id, name: 'Sample2'))
        Paleolog::Repo.save(Paleolog::Occurrence.new(counting_id: counting_id, sample_id: sample_id, species_id: species1_id))
        Paleolog::Repo.save(Paleolog::Occurrence.new(counting_id: counting_id, sample_id: sample_id, species_id: species3_id))

        tested = repo.available_species_ids(counting_id, other_sample_id, group_id)
        assert_equal 3, tested.size
        assert_includes tested, species1_id
        assert_includes tested, species2_id
        assert_includes tested, species3_id
      end
    end
  end
end
