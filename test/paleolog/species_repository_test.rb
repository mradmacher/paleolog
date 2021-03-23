# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repositories::SpeciesRepository do
  before do
    @group_repository = Paleolog::Repositories::GroupRepository.new(Paleolog::Repositories::Repository.db)
    @repository = Paleolog::Repositories::SpeciesRepository.new(Paleolog::Repositories::Repository.db)

    @repository.clear
    @group_repository.clear
  end

  describe '#find' do
    it 'find species and assigns group' do
      group = @group_repository.create(name: 'Dinoflagellate')
      species = @group_repository.add_species(group, name: 'Costata')
      # species = @repository.create(name: 'Odontochitina costata', group_id: group.id)

      result = @repository.find(species.id)
      assert_equal group.attributes, result.group.attributes
    end
  end

  describe '#search_verified' do
    let(:group1) { @group_repository.create(Paleolog::Group.new(name: 'Dinoflagellate')) }
    let(:group2) { @group_repository.create(Paleolog::Group.new(name: 'Other')) }
    let(:species1) { @repository.create(Paleolog::Species.new(name: 'Odontochitina costata', group: group1)) }
    let(:species2) { @repository.create(Paleolog::Species.new(name: 'Cerodinium diebelii', group: group1)) }
    let(:species3) { @repository.create(Paleolog::Species.new(name: 'Acritarchs', group: group2)) }

    describe 'when no filters provided' do
      let(:filters) { {} }

      it 'returns only verified' do
        assert @repository.search_verified(filters).empty?

        @repository.update(species2.id, verified: true)
        result = @repository.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species2.id
        refute_nil result.first.group
      end
    end

    describe 'when group filter provided' do
      let(:filters) { { group_id: group1.id } }

      it 'returns only verified that match filter' do
        assert @repository.search_verified(filters).empty?

        @repository.update(species1.id, verified: true)
        @repository.update(species2.id, verified: false)
        @repository.update(species3.id, verified: true)
        result = @repository.search_verified(filters)
        assert_equal 1, result.size

        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end
    end

    describe 'when name filter provided' do
      let(:filters) { { name: 'costa' } }

      it 'returns only verified that match filter' do
        assert @repository.search_verified(filters).empty?

        @repository.update(species1.id, verified: true)
        @repository.update(species2.id, verified: true)
        @repository.update(species3.id, verified: true)
        result = @repository.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end

      it 'is case insensitive' do
        @repository.update(species1.id, verified: true)
        refute @repository.search_verified(name: 'odonto').empty?
      end
    end

    describe 'when name and group filters provided' do
      let(:filters) { { group_id: group1.id, name: 'costa' } }

      it 'returns only verified that match filter' do
        assert @repository.search_verified(filters).empty?

        @repository.update(species1.id, verified: true)
        @repository.update(species2.id, verified: true)
        @repository.update(species3.id, verified: true)
        result = @repository.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end
    end
  end
end
