# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repositories::GroupRepository do
  before do
    @repository = Paleolog::Repositories::GroupRepository.new(Paleolog::Repositories::Repository.db)
    @repository.clear
  end

  it 'persists group' do
    group = @repository.create(name: 'Dinoflagellate')
    refute_nil group.id
    result = @repository.find(group.id)
    assert_equal result, group
  end

  describe '#all' do
    it 'returns all groups' do
      group1 = @repository.create(name: 'Dinoflagellate')
      group2 = @repository.create(name: 'Other')

      result = @repository.all
      assert_equal 2, result.size
      # expect(repository.all).to eq([group1, group2])
    end
  end
end
