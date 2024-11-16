# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Project do
  let(:repo) { Paleolog::Repo::Project }

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
