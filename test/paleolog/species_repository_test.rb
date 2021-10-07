# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Species do
  before do
    @group_repo = Paleolog::Repo::Group.new
    @field_repo = Paleolog::Repo::Field.new
    @species_repo = Paleolog::Repo::Species.new

    @species_repo.delete_all
    @group_repo.delete_all
  end

  describe '#find' do
    it 'find species and assigns group' do
      group = @group_repo.create(name: 'Dinoflagellate')
      species = @group_repo.add_species(group, name: 'Costata')

      result = @species_repo.find_by_id(species.id)
      assert_equal group, result.group
    end
  end

  describe '#find_by_id' do
    before do
      @group = @group_repo.create(name: 'Dinoflagellate')
      @field = @group_repo.add_field(@group, name: 'Type')
      @choice = @field_repo.add_choice(@field, name: 'G')
      @species = @group_repo.add_species(@group, name: 'Odontochitina costata')
      @species_repo.add_feature(@species, @choice)
      @species_repo.add_image(@species, image_file_name: 'nice_picture.jpg')
    end

    it 'finds species and loads all dependencies' do
      result = @species_repo.find_by_id(@species.id)
      refute_nil result.group
      refute_nil result.choices
      assert_equal 1, result.choices.size
      refute_nil result.choices.first.field
      refute_nil result.images
      assert_equal 1, result.images.size
    end
  end

  describe '#search_verified' do
    let(:group1) { @group_repo.create(name: 'Dinoflagellate') }
    let(:group2) { @group_repo.create(name: 'Other') }
    let(:species1) { @group_repo.add_species(group1, name: 'Odontochitina costata') }
    let(:species2) { @group_repo.add_species(group1, name: 'Cerodinium diebelii') }
    let(:species3) { @group_repo.add_species(group2, name: 'Acritarchs') }

    describe 'when no filters provided' do
      let(:filters) { {} }

      it 'returns only verified' do
        assert @species_repo.search_verified(filters).empty?

        @species_repo.update(species2.id, verified: true)
        result = @species_repo.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species2.id
        refute_nil result.first.group
      end
    end

    describe 'when group filter provided' do
      let(:filters) { { group_id: group1.id } }

      it 'returns only verified that match filter' do
        assert @species_repo.search_verified(filters).empty?

        @species_repo.update(species1.id, verified: true)
        @species_repo.update(species2.id, verified: false)
        @species_repo.update(species3.id, verified: true)
        result = @species_repo.search_verified(filters)
        assert_equal 1, result.size

        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end
    end

    describe 'when name filter provided' do
      let(:filters) { { name: 'costa' } }

      it 'returns only verified that match filter' do
        assert @species_repo.search_verified(filters).empty?

        @species_repo.update(species1.id, verified: true)
        @species_repo.update(species2.id, verified: true)
        @species_repo.update(species3.id, verified: true)
        result = @species_repo.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end

      it 'is case insensitive' do
        @species_repo.update(species1.id, verified: true)
        refute @species_repo.search_verified(name: 'odonto').empty?
      end
    end

    describe 'when name and group filters provided' do
      let(:filters) { { group_id: group1.id, name: 'costa' } }

      it 'returns only verified that match filter' do
        assert @species_repo.search_verified(filters).empty?

        @species_repo.update(species1.id, verified: true)
        @species_repo.update(species2.id, verified: true)
        @species_repo.update(species3.id, verified: true)
        result = @species_repo.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end
    end
  end
end
