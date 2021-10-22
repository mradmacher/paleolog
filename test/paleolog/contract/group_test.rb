# frozen_string_literal: true

require 'test_helper'
require_relative './common_assertions'

describe Paleolog::Contract::Group do
  include CommonAssertions

  before do
    @schema = Paleolog::Contract::GroupSchema
    @group_repo = MiniTest::Mock.new
    @contract = Paleolog::Contract::Group.new(group_repo: @group_repo)
  end

  it 'validates name' do
    assert_requires_string(@schema, :name)
    assert_strips_string(@schema, :name)
    assert_restricts_string_length(@schema, :name, max: 255)
  end

  it 'does not complain when name not taken yet' do
    @group_repo.expect(:name_exists?, false, ['Group Name'])
    refute(@contract.call(name: 'Group Name').error?(:name))
    @group_repo.verify
  end

  it 'complains when name already exists' do
    @group_repo.expect(:name_exists?, true, ['Group Name'])
    result = @contract.call(name: 'Group Name')
    assert(result.errors[:name].include?('is already taken'))
    @group_repo.verify
  end
end
