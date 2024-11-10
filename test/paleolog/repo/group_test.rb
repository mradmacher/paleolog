# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Group do
  let(:repo) { Paleolog::Repo::Group }

  after do
    repo.delete_all
  end

  describe '#name_exists?' do
    it 'checks name uniqueness' do
      Paleolog::Repo.save(Paleolog::Group.new(name: 'Some name'))

      assert(repo.name_exists?('Some name'))
      refute(repo.name_exists?('Other name'))
    end

    it 'is case insensitive' do
      Paleolog::Repo.save(Paleolog::Group.new(name: 'Some name'))

      assert(repo.name_exists?('sOme NamE'))
    end
  end

  it 'persists and finds groups' do
    group_id = Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate'))

    refute_nil group_id
    result = Paleolog::Repo.find(Paleolog::Group, group_id)

    assert_equal group_id, result.id
  end
end
