# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Species do
  let(:repo) { Paleolog::Repo::Species.new }

  after do
    repo.delete_all
    Paleolog::Repo::Group.new.delete_all
  end

  describe '#find' do
    it 'find species and assigns group' do
      group = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
      species = Paleolog::Repo.save(Paleolog::Species.new(name: 'Costata', verified: true, group: group))

      result = Paleolog::Repo.find(Paleolog::Species, species.id)
      assert_equal group.name, result.group.name
    end

    it 'finds species and loads all dependencies' do
      group = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
      species = Paleolog::Repo.save(Paleolog::Species.new(name: 'Costata', verified: true, group: group))

      field = Paleolog::Repo.save(Paleolog::Field.new(name: 'Type'))
      choice = Paleolog::Repo.save(Paleolog::Choice.new(name: 'G', field: field))
      Paleolog::Repo.save(Paleolog::Feature.new(species: species, choice: choice))

      Paleolog::Repo.save(Paleolog::Image.new(species: species, image_file_name: 'nice_picture.jpg'))

      result = Paleolog::Repo.find(Paleolog::Species, species.id)
      refute_nil result.group
      refute result.features.empty?

      assert_equal 1, result.features.size
      refute_nil result.features.first.choice.field
      assert_equal field.name, result.features.first.choice.field.name
      refute result.images.empty?
      assert_equal 1, result.images.size
    end
  end

  describe '#all_with_ids' do
    it 'returns species for given ids' do
      group = Paleolog::Repo.save(Paleolog::Group.new(name: 'Group'))
      species1 = Paleolog::Repo.save(Paleolog::Species.new(name: 'S1', group: group))
      species2 = Paleolog::Repo.save(Paleolog::Species.new(name: 'S2', group: group))
      species3 = Paleolog::Repo.save(Paleolog::Species.new(name: 'S3', group: group))

      result = repo.all_with_ids([species1.id, species3.id])
      assert_equal([species1.id, species3.id].sort, result.map(&:id))
    end

    it 'loads group' do
      group1 = Paleolog::Repo.save(Paleolog::Group.new(name: 'G1'))
      species1 = Paleolog::Repo.save(Paleolog::Species.new(name: 'S1', group: group1))
      group2 = Paleolog::Repo.save(Paleolog::Group.new(name: 'G2'))
      species2 = Paleolog::Repo.save(Paleolog::Species.new(name: 'S2', group: group2))

      result = repo.all_with_ids([species1.id, species2.id])
      assert_equal(%w(G1 G2), result.map { |s| s.group.name })
    end

    it 'loads features' do
      group = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
      species = Paleolog::Repo.save(Paleolog::Species.new(name: 'Costata', verified: true, group: group))

      field = Paleolog::Repo.save(Paleolog::Field.new(name: 'Type'))
      choice = Paleolog::Repo.save(Paleolog::Choice.new(name: 'G', field: field))
      Paleolog::Repo.save(Paleolog::Feature.new(species: species, choice: choice))

      result = repo.all_with_ids([species.id]).first
      refute result.features.empty?

      assert_equal 1, result.features.size
      refute_nil result.features.first.choice.field
      assert_equal field.name, result.features.first.choice.field.name
    end
  end

  describe '#all_for_group' do
    let(:group) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Some Group')) }
    let(:other_group) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Other Group')) }

    it 'returns all species in a given group' do
      species1 = Paleolog::Repo.save(Paleolog::Species.new(name: 'S1', group: group))
      species2 = Paleolog::Repo.save(Paleolog::Species.new(name: 'S2', group: group))
      species3 = Paleolog::Repo.save(Paleolog::Species.new(name: 'S3', group: other_group))

      result = repo.all_for_group(group.id)
      assert_equal([species1.id, species2.id].sort, result.map(&:id))
    end
  end

  describe '#name_exists_within_group?' do
    before do
      @group = Paleolog::Repo.save(Paleolog::Group.new(name: 'Some group'))
    end

    it 'checks name uniqueness within group scope' do
      Paleolog::Repo.save(Paleolog::Species.new(name: 'Some species', group: @group))

      assert(repo.name_exists_within_group?('Some species', @group.id))
      refute(repo.name_exists_within_group?('Other species', @group.id))
    end

    it 'is case insensitive' do
      Paleolog::Repo.save(Paleolog::Species.new(name: 'Some species', group: @group))

      assert(repo.name_exists_within_group?('soMe sPeCies', @group.id))
    end
  end

  describe '#search_verified' do
    let(:group1) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate')) }
    let(:group2) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Other')) }
    let(:species1) { Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Odontochitina costata')) }
    let(:species2) { Paleolog::Repo.save(Paleolog::Species.new(group: group1, name: 'Cerodinium diebelii')) }
    let(:species3) { Paleolog::Repo.save(Paleolog::Species.new(group: group2, name: 'Acritarchs')) }

    describe 'when no filters provided' do
      let(:filters) { {} }

      it 'returns only verified' do
        assert repo.search_verified(filters).empty?

        repo.update(species2.id, verified: true)
        result = repo.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species2.id
        refute_nil result.first.group
      end
    end

    describe 'when group filter provided' do
      let(:filters) { { group_id: group1.id } }

      it 'returns only verified that match filter' do
        assert repo.search_verified(filters).empty?

        repo.update(species1.id, verified: true)
        repo.update(species2.id, verified: false)
        repo.update(species3.id, verified: true)
        result = repo.search_verified(filters)
        assert_equal 1, result.size

        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end
    end

    describe 'when name filter provided' do
      let(:filters) { { name: 'costa' } }

      it 'returns only verified that match filter' do
        assert repo.search_verified(filters).empty?

        repo.update(species1.id, verified: true)
        repo.update(species2.id, verified: true)
        repo.update(species3.id, verified: true)
        result = repo.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end

      it 'is case insensitive' do
        repo.update(species1.id, verified: true)
        refute repo.search_verified(name: 'odonto').empty?
      end
    end

    describe 'when name and group filters provided' do
      let(:filters) { { group_id: group1.id, name: 'costa' } }

      it 'returns only verified that match filter' do
        assert repo.search_verified(filters).empty?

        repo.update(species1.id, verified: true)
        repo.update(species2.id, verified: true)
        repo.update(species3.id, verified: true)
        result = repo.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end
    end
  end
end
