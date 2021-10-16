# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Contract::Group do
  before do
    @group_repo = Paleolog::Repo::Group.new
    @contract = Paleolog::Contract::Group.new(group_repo: @group_repo)
  end

  it 'requires name' do
    result = @contract.call(name: nil)
    assert(result.errors[:name].include?('must be a string'))

    result = @contract.call(name: '')
    assert(result.errors[:name].include?('must be filled'))

    result = @contract.call(name: '   ')
    assert(result.errors[:name].include?('must be filled'))

    result = @contract.call(name: 'something')
    refute(result.error?(:name))
  end

  it 'strips name' do
    result = @contract.call(name: '  some thing   ')
    assert_equal('some thing', result[:name])
  end

  it 'requires size to be less than 255 characters' do
    result = @contract.call(name: 'a' * 255)
    refute(result.error?(:name))

    result = @contract.call(name: 'a' * 256)
    assert(result.errors[:name].include?('size cannot be greater than 255'))
  end

  it 'checks name uniqueness' do
    attrs = { name: 'Group Name   ' }

    @group_repo.create(name: 'Group Name')
    result = @contract.call(attrs)
    assert(result.errors[:name].include?('is already taken'))

    @group_repo.delete_all
    result = @contract.call(attrs)
    refute(result.error?(:name))
  end
end
