# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Group do
  before do
    @repo = Paleolog::Repo::Group.new
  end

  after do
    @repo.delete_all
  end

  describe '#name_exists?' do
    it 'checks name uniqueness' do
      Paleolog::Repo.save(Paleolog::Group.new(name: 'Some name'))

      assert(@repo.name_exists?('Some name'))
      refute(@repo.name_exists?('Other name'))
    end

    it 'is case insensitive' do
      Paleolog::Repo.save(Paleolog::Group.new(name: 'Some name'))

      assert(@repo.name_exists?('sOme NamE'))
    end
  end

  it 'persists and finds groups' do
    group = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))
    refute_nil group.id
    result = Paleolog::Repo.find(Paleolog::Group, group.id)
    assert_equal result, group
  end
end
