# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Species do
  let(:repo) { Paleolog::Repo::Species }

  after do
    repo.delete_all
    Paleolog::Repo::Group.delete_all

    Paleolog::Repo::Project.delete_all
  end

  describe '#search' do
    let(:group1_id) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate')) }
    let(:group2_id) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Other')) }
    let(:species1_id) { Paleolog::Repo.save(Paleolog::Species.new(group_id: group1_id, name: 'Odontochitina costata')) }
    let(:species2_id) { Paleolog::Repo.save(Paleolog::Species.new(group_id: group1_id, name: 'Cerodinium diebelii')) }
    let(:species3_id) { Paleolog::Repo.save(Paleolog::Species.new(group_id: group2_id, name: 'Acritarchs')) }

    before do
      species1_id
      species2_id
      species3_id
    end

    describe 'when verified filter provided' do
      let(:filters) { { verified: true } }

      it 'returns only verified' do
        assert_empty repo.search(filters)

        repo.update(species2_id, verified: true)
        result = repo.search(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species2_id
        refute_nil result.first.group
      end
    end

    describe 'when group filter provided' do
      let(:filters) { { group_id: group1_id } }

      it 'returns only species that match filter' do
        result = repo.search(filters)
        assert_equal 2, result.size

        assert_equal result.map(&:id), [species1_id, species2_id]
        refute_nil result.first.group
      end
    end

    describe 'when name filter provided' do
      let(:filters) { { name: 'costa' } }

      it 'returns only species that match filter' do
        result = repo.search(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1_id
        refute_nil result.first.group
      end

      it 'is case insensitive' do
        refute_empty repo.search(name: 'odonto')
      end
    end

    describe 'when project filter provided' do
      let(:project_id) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Test Project')) }
      let(:other_project_id) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Test Project')) }
      let(:filters) { { project_id: project_id } }

      it 'displays species from occurrences' do
        section_id = Paleolog::Repo::Section.create(name: 'Some section', project_id: project_id)
        counting_id = Paleolog::Repo.save(Paleolog::Counting.new(name: 'Some counting', project_id: project_id))
        sample_id = Paleolog::Repo.save(Paleolog::Sample.new(name: 'Some sample', section_id: section_id))
        Paleolog::Repo.save(
          Paleolog::Occurrence.new(
            rank: 1,
            species_id: species1_id,
            counting_id: counting_id,
            sample_id: sample_id,
          ),
        )

        result = repo.search({ project_id: project_id, name: 'costa' })
        assert_equal 1, result.size
        assert_equal result.first.id, species1_id
        refute_nil result.first.group
      end
    end

    describe 'when name, group and verified filters provided' do
      let(:filters) { { group_id: group1_id, name: 'costa', verified: true } }

      it 'returns only verified that match filter' do
        assert_empty repo.search(filters)

        repo.update(species1_id, verified: true)
        repo.update(species2_id, verified: true)
        repo.update(species3_id, verified: true)
        result = repo.search(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1_id
        refute_nil result.first.group
      end
    end
  end
end
