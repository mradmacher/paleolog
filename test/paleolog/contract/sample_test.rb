# frozen_string_literal: true

require 'test_helper'
require_relative './common_assertions'

describe Paleolog::Contract::Sample do
  include CommonAssertions

  before do
    @schema = Paleolog::Contract::SampleSchema
    @sample_repo = Minitest::Mock.new
    @contract = Paleolog::Contract::Sample.new(sample_repo: @sample_repo)
  end

  it 'validates name' do
    assert_requires_string(@schema, :name)
    assert_strips_string(@schema, :name)
    assert_restricts_string_length(@schema, :name, max: 255)
  end

  it 'requires section id' do
    assert_requires_integer(@schema, :section_id)
    assert_performs_integer_coertion(@contract, :section_id)
  end

  it 'does not complain when name not taken yet in section scope' do
    @sample_repo.expect(:name_exists_within_section?, false, ['Name', 1])
    refute(@contract.call(name: 'Name', section_id: 1).error?(:name))
    @sample_repo.verify
  end

  it 'complains when name already exists' do
    @sample_repo.expect(:name_exists_within_section?, true, ['Name', 1])
    result = @contract.call(name: 'Name', section_id: 1)
    assert(result.errors[:name].include?('is already taken'))
    @sample_repo.verify
  end

  it 'does not complain when rank not taken yet in section scope' do
    @sample_repo.expect(:rank_exists_within_section?, false, [1, 1])
    refute(@contract.call(rank: 1, section_id: 1).error?(:rank))
    @sample_repo.verify
  end

  it 'complains when rank already exists' do
    @sample_repo.expect(:rank_exists_within_section?, true, [1, 1])
    result = @contract.call(rank: 1, section_id: 1)
    assert(result.errors[:rank].include?('is already taken'))
    @sample_repo.verify
  end

  it 'does not require weight' do
    result = @schema.call(weight: nil)
    refute(result.error?(:weight))

    result = @schema.call(weight: '')
    refute(result.error?(:weight))
    assert(result.to_h[:weight].nil?)
  end

  it 'requires numerical weight when present' do
    ['  ', 'a', '#', '34a', 'a34'].each do |value|
      result = @schema.call(weight: value)
      assert(result.error?(:weight))
      assert(result.errors[:weight].include?('must be a decimal'))
    end

    result = @schema.call(weight: '1.3')
    refute(result.error?(:weight))
    assert_equal(1.3, result.to_h[:weight])

    result = @schema.call(weight: 1.3)
    refute(result.error?(:weight))
    assert_equal(1.3, result.to_h[:weight])

    result = @schema.call(weight: 13)
    refute(result.error?(:weight))
    assert_equal(13.0, result.to_h[:weight])
  end

  it 'requires weight greater than 0 when present' do
    result = @schema.call(weight: 0)
    assert(result.error?(:weight))
    assert(result.errors[:weight].include?('must be greater than 0'))

    result = @schema.call(weight: 0.0)
    assert(result.error?(:weight))
    assert(result.errors[:weight].include?('must be greater than 0'))

    result = @schema.call(weight: -0.1)
    assert(result.error?(:weight))
    assert(result.errors[:weight].include?('must be greater than 0'))

    [0.1, 2.0, 0.000001, 20].each do |value|
      result = @schema.call(weight: value)
      refute(result.error?(:weight))
    end
  end

  it 'requires a rank' do
    assert_requires_integer(@schema, :rank)
    assert_performs_integer_coertion(@schema, :rank)
	end
end
