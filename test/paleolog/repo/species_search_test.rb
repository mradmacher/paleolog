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
    let(:group1) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate')) }
    let(:group2) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Other')) }
    let(:species1) { Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Odontochitina costata')) }
    let(:species2) { Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Cerodinium diebelii')) }
    let(:species3) { Paleolog::Repo.save(Paleolog::Species.new(group: group2, name: 'Acritarchs')) }

    before do
      species1
      species2
      species3
    end

    describe 'when verified filter provided' do
      let(:filters) { { verified: true } }

      it 'returns only verified' do
        assert repo.search(filters).empty?

        repo.update(species2.id, verified: true)
        result = repo.search(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species2.id
        refute_nil result.first.group
      end
    end

    describe 'when group filter provided' do
      let(:filters) { { group_id: group1.id } }

      it 'returns only species that match filter' do
        result = repo.search(filters)
        assert_equal 2, result.size

        assert_equal result.map(&:id), [species1.id, species2.id]
        refute_nil result.first.group
      end
    end

    describe 'when name filter provided' do
      let(:filters) { { name: 'costa' } }

      it 'returns only species that match filter' do
        result = repo.search(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end

      it 'is case insensitive' do
        refute repo.search(name: 'odonto').empty?
      end
    end

    describe 'when project filter provided' do
      let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Test Project')) }
      let(:other_project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Test Project')) }
      let(:filters) { { project_id: project.id } }

      it 'displays species from occurrences' do
        section = Paleolog::Repo::Section.create(name: 'Some section', project_id: project.id)
        counting = Paleolog::Repo.save(Paleolog::Counting.new(name: 'Some counting', project: project))
        sample = Paleolog::Repo.save(Paleolog::Sample.new(name: 'Some sample', section: section))
        Paleolog::Repo.save(
          Paleolog::Occurrence.new(
            rank: 1,
            species_id: species1.id,
            counting_id: counting.id,
            sample_id: sample.id,
          ),
        )

        result = repo.search({ project_id: project.id, name: 'costa' })
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end

      it 'displays species from project images' do
        section = Paleolog::Repo.save(Paleolog::Section.new(name: 'Some section', project: project))
        sample = Paleolog::Repo.save(Paleolog::Sample.new(name: 'Some sample', section: section))
        Paleolog::Repo.save(Paleolog::Image.new(image_file_name: 'img1.png', species: species1, sample: sample))

        result = repo.search({ project_id: project.id, name: 'costa' })
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end
    end

    describe 'when name, group and verified filters provided' do
      let(:filters) { { group_id: group1.id, name: 'costa', verified: true } }

      it 'returns only verified that match filter' do
        assert repo.search(filters).empty?

        repo.update(species1.id, verified: true)
        repo.update(species2.id, verified: true)
        repo.update(species3.id, verified: true)
        result = repo.search(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end
    end
  end
end
