# frozen_string_literal: true

require 'test_helper'
require_relative './common_assertions'

describe Paleolog::Contract::Choice do
  include CommonAssertions

  before do
    @schema = Paleolog::Contract::ChoiceSchema
    @choice_repo = MiniTest::Mock.new
    @contract = Paleolog::Contract::Choice.new(choice_repo: @choice_repo)
  end

  it 'validates name' do
    assert_requires_string(@schema, :name)
    assert_strips_string(@schema, :name)
    assert_restricts_string_length(@schema, :name, max: 255)
  end

  it 'requires field id' do
    assert_requires_integer(@contract, :field_id)
    assert_performs_integer_coertion(@contract, :field_id)
  end

  it 'does not complain when name not taken yet' do
    @choice_repo.expect(:name_exists_within_field?, false, ['Name', 1])
    refute(@contract.call(name: 'Name', field_id: 1).error?(:name))
    @choice_repo.verify
  end

  it 'complains when name already exists' do
    @choice_repo.expect(:name_exists_within_field?, true, ['Name', 1])
    result = @contract.call(name: 'Name', field_id: 1)
    assert(result.errors[:name].include?('is already taken'))
    @choice_repo.verify
  end
end
