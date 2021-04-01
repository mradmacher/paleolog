# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repository::Species do
  before do
    @group_repository = Paleolog::Repository::Group.new(Paleolog::Repository::Config.db)
    @field_repository = Paleolog::Repository::Field.new(Paleolog::Repository::Config.db)
    @species_repository = Paleolog::Repository::Species.new(Paleolog::Repository::Config.db)

    @species_repository.clear
    @group_repository.clear
  end

  describe '#find' do
    it 'find species and assigns group' do
      group = @group_repository.create(name: 'Dinoflagellate')
      species = @group_repository.add_species(group, name: 'Costata')

      result = @species_repository.find(species.id)
      assert_equal group.attributes, result.group.attributes
    end
  end

  describe '#find_with_dependencies' do
    before do
      @group = @group_repository.create(name: 'Dinoflagellate')
      @field = @group_repository.add_field(@group, name: 'Type')
      @choice = @field_repository.add_choice(@field, name: 'G')
      @species = @group_repository.add_species(@group, name: 'Odontochitina costata')
      @species_repository.add_feature(@species, @choice)
      @species_repository.add_image(@species, image_file_name: 'nice_picture.jpg')
    end

    it 'finds species and loads all dependencies' do
      result = @species_repository.find_with_dependencies(@species.id)
      refute_nil result.group
      refute_nil result.choices
      assert_equal 1, result.choices.size
      refute_nil result.choices.first.field
      refute_nil result.images
      assert_equal 1, result.images.size
    end
  end

  describe '#search_verified' do
    let(:group1) { @group_repository.create(name: 'Dinoflagellate') }
    let(:group2) { @group_repository.create(name: 'Other') }
    let(:species1) { @group_repository.add_species(group1, name: 'Odontochitina costata') }
    let(:species2) { @group_repository.add_species(group1, name: 'Cerodinium diebelii') }
    let(:species3) { @group_repository.add_species(group2, name: 'Acritarchs') }

    describe 'when no filters provided' do
      let(:filters) { {} }

      it 'returns only verified' do
        assert @species_repository.search_verified(filters).empty?

        @species_repository.update(species2.id, verified: true)
        result = @species_repository.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species2.id
        refute_nil result.first.group
      end
    end

    describe 'when group filter provided' do
      let(:filters) { { group_id: group1.id } }

      it 'returns only verified that match filter' do
        assert @species_repository.search_verified(filters).empty?

        @species_repository.update(species1.id, verified: true)
        @species_repository.update(species2.id, verified: false)
        @species_repository.update(species3.id, verified: true)
        result = @species_repository.search_verified(filters)
        assert_equal 1, result.size

        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end
    end

    describe 'when name filter provided' do
      let(:filters) { { name: 'costa' } }

      it 'returns only verified that match filter' do
        assert @species_repository.search_verified(filters).empty?

        @species_repository.update(species1.id, verified: true)
        @species_repository.update(species2.id, verified: true)
        @species_repository.update(species3.id, verified: true)
        result = @species_repository.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end

      it 'is case insensitive' do
        @species_repository.update(species1.id, verified: true)
        refute @species_repository.search_verified(name: 'odonto').empty?
      end
    end

    describe 'when name and group filters provided' do
      let(:filters) { { group_id: group1.id, name: 'costa' } }

      it 'returns only verified that match filter' do
        assert @species_repository.search_verified(filters).empty?

        @species_repository.update(species1.id, verified: true)
        @species_repository.update(species2.id, verified: true)
        @species_repository.update(species3.id, verified: true)
        result = @species_repository.search_verified(filters)
        assert_equal 1, result.size
        assert_equal result.first.id, species1.id
        refute_nil result.first.group
      end
    end
  end
end
