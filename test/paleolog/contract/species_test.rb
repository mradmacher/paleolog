# frozen_string_literal: true

require 'test_helper'
require_relative './common_assertions'

describe Paleolog::Contract::Species do
  include CommonAssertions

  before do
    @schema = Paleolog::Contract::SpeciesSchema
    @species_repo = MiniTest::Mock.new
    @contract = Paleolog::Contract::Species.new(species_repo: @species_repo)
  end

  it 'validates name' do
    assert_requires_string(@schema, :name)
    assert_strips_string(@schema, :name)
    assert_restricts_string_length(@schema, :name, max: 255)
  end

  it 'does not allow same names within a group' do
    @species_repo.expect(:name_exists_within_group?, true, ['Name', 1])
    result = @contract.call(name: 'Name', group_id: 1)
    assert(result.error?(:name))
    assert(result.errors[:name].include?('is already taken'))
  end

  it 'allows different names within a group' do
    @species_repo.expect(:name_exists_within_group?, false, ['Name', 1])
    result = @contract.call(name: 'Name', group_id: 1)
    refute(result.error?(:name))
  end

  it 'requires group id' do
    assert_requires_integer(@schema, :group_id)
  end

  it 'requires description length to be less than 4096 characters' do
    result = @schema.call(description: 'a' * 4096)
    refute(result.error?(:description))

    result = @schema.call(description: 'a' * (4096 + 1))
    assert(result.error?(:description))
    assert(result.errors[:description].include?('size cannot be greater than 4096'))
  end

  it 'requires environmental preferences length to be less than 4096 characters' do
    result = @schema.call(environmental_preferences: 'a' * 4096)
    refute(result.error?(:environmental_preferences))

    result = @schema.call(environmental_preferences: 'a' * (4096 + 1))
    assert(result.error?(:environmental_preferences))
    assert(result.errors[:environmental_preferences].include?('size cannot be greater than 4096'))
  end
end
