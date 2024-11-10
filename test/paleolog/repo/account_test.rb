# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Account do
  let(:repo) { Paleolog::Repo::Account }

  after do
    repo.delete_all
  end

  it 'saves and finds' do
    id = Paleolog::Repo.save(Paleolog::Account.new(name: 'Test Account'))
    result = repo.find(id)
    assert_equal 'Test Account', result.name
  end

  describe '#similar_name_exists?' do
    it 'checks name uniqueness' do
      repo.create(name: 'Some name')

      assert(repo.similar_name_exists?('Some name'))
      refute(repo.similar_name_exists?('Other name'))
    end

    it 'is case insensitive' do
      repo.create(name: 'Some name')

      assert(repo.similar_name_exists?('sOme NamE'))
    end
  end
end
