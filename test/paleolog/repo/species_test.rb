# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Species do
  let(:repo) { Paleolog::Repo::Species }

  after do
    repo.delete_all
    Paleolog::Repo::Group.delete_all

    Paleolog::Repo::Project.delete_all
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
      refute_empty result.features

      assert_equal 1, result.features.size
      refute_nil result.features.first.choice.field
      assert_equal field.name, result.features.first.choice.field.name
      refute_empty result.images
      assert_equal 1, result.images.size
    end
  end

  describe '#all_with_ids' do
    it 'returns species for given ids' do
      group = Paleolog::Repo.save(Paleolog::Group.new(name: 'Group'))
      species1 = Paleolog::Repo.save(Paleolog::Species.new(name: 'S1', group: group))
      Paleolog::Repo.save(Paleolog::Species.new(name: 'S2', group: group))
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
      assert_equal(%w[G1 G2], result.map { |s| s.group.name })
    end

    it 'loads features' do
      group = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
      species = Paleolog::Repo.save(Paleolog::Species.new(name: 'Costata', verified: true, group: group))

      field = Paleolog::Repo.save(Paleolog::Field.new(name: 'Type'))
      choice = Paleolog::Repo.save(Paleolog::Choice.new(name: 'G', field: field))
      Paleolog::Repo.save(Paleolog::Feature.new(species: species, choice: choice))

      result = repo.all_with_ids([species.id]).first
      refute_empty result.features

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
      Paleolog::Repo.save(Paleolog::Species.new(name: 'S3', group: other_group))

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
end
