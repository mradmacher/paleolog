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
      group_id = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
      species_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'Costata', verified: true, group_id: group_id))

      result = Paleolog::Repo.find(Paleolog::Species, species_id)
      assert_equal 'Dinoflagellate', result.group.name
    end

    it 'finds species and loads all dependencies' do
      group_id = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
      species_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'Costata', verified: true, group_id: group_id))

      field_id = Paleolog::Repo.save(Paleolog::Field.new(name: 'Type'))
      choice_id = Paleolog::Repo.save(Paleolog::Choice.new(name: 'G', field_id: field_id))
      Paleolog::Repo.save(Paleolog::Feature.new(species_id: species_id, choice_id: choice_id))

      Paleolog::Repo.save(Paleolog::Image.new(species_id: species_id, image_file_name: 'nice_picture.jpg'))

      result = Paleolog::Repo.find(Paleolog::Species, species_id)
      refute_nil result.group
      refute_empty result.features

      assert_equal 1, result.features.size
      refute_nil result.features.first.choice.field
      assert_equal 'Type', result.features.first.choice.field.name
      refute_empty result.images
      assert_equal 1, result.images.size
    end
  end

  describe '#all_with_ids' do
    it 'returns species for given ids' do
      group_id = Paleolog::Repo.save(Paleolog::Group.new(name: 'Group'))
      species1_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'S1', group_id: group_id))
      Paleolog::Repo.save(Paleolog::Species.new(name: 'S2', group_id: group_id))
      species3_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'S3', group_id: group_id))

      result = repo.all_with_ids([species1_id, species3_id])
      assert_equal([species1_id, species3_id].sort, result.map(&:id))
    end

    it 'loads group' do
      group1_id = Paleolog::Repo.save(Paleolog::Group.new(name: 'G1'))
      species1_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'S1', group_id: group1_id))
      group2_id = Paleolog::Repo.save(Paleolog::Group.new(name: 'G2'))
      species2_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'S2', group_id: group2_id))

      result = repo.all_with_ids([species1_id, species2_id])
      assert_equal(%w[G1 G2], result.map { |s| s.group.name })
    end

    it 'loads features' do
      group_id = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
      species_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'Costata', verified: true, group_id: group_id))

      field_id = Paleolog::Repo.save(Paleolog::Field.new(name: 'Type'))
      choice_id = Paleolog::Repo.save(Paleolog::Choice.new(name: 'G', field_id: field_id))
      Paleolog::Repo.save(Paleolog::Feature.new(species_id: species_id, choice_id: choice_id))

      result = repo.all_with_ids([species_id]).first
      refute_empty result.features

      assert_equal 1, result.features.size
      refute_nil result.features.first.choice.field
      assert_equal 'Type', result.features.first.choice.field.name
    end
  end

  describe '#all_for_group' do
    let(:group_id) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Some Group')) }
    let(:other_group_id) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Other Group')) }

    it 'returns all species in a given group' do
      species1_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'S1', group_id: group_id))
      species2_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'S2', group_id: group_id))
      Paleolog::Repo.save(Paleolog::Species.new(name: 'S3', group_id: other_group_id))

      result = repo.all_for_group(group_id)
      assert_equal([species1_id, species2_id].sort, result.map(&:id))
    end
  end

  describe '#name_exists?' do
    before do
      @group_id = Paleolog::Repo.save(Paleolog::Group.new(name: 'Some group'))
    end

    it 'checks name uniqueness within same group' do
      Paleolog::Repo.save(Paleolog::Species.new(name: 'Some species', group_id: @group_id))

      assert(repo.name_exists?('Some species'))
      refute(repo.name_exists?('Other species'))
    end

    it 'checks name uniqueness within other group' do
      other_group_id = Paleolog::Repo.save(Paleolog::Group.new(name: 'Some other group'))
      Paleolog::Repo.save(Paleolog::Species.new(name: 'Some species', group_id: other_group_id))

      assert(repo.name_exists?('Some species'))
      refute(repo.name_exists?('Other species'))
    end

    it 'is case insensitive' do
      Paleolog::Repo.save(Paleolog::Species.new(name: 'Some species', group_id: @group_id))

      assert(repo.name_exists?('soMe sPeCies'))
    end

    it 'does not verify with itself' do
      species_id = Paleolog::Repo.save(Paleolog::Species.new(name: 'Some species', group_id: @group_id))

      refute(repo.name_exists?('Other species', exclude_id: species_id))
    end
  end
end
