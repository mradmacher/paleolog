# frozen_string_literal: true

require 'test_helper'
require_relative './common_assertions'

describe Paleolog::Contract::Occurrence do
  include CommonAssertions

  before do
    @schema = Paleolog::Contract::OccurrenceSchema
    @occurrence_repo = MiniTest::Mock.new
    @contract = Paleolog::Contract::Occurrence.new(occurrence_repo: @occurrence_repo)
  end

  it 'requires species id' do
    assert_requires_integer(@schema, :species_id)
  end

  it 'requires counting id' do
    assert_requires_integer(@schema, :counting_id)
  end

  it 'requires sample id' do
    assert_requires_integer(@schema, :sample_id)
  end

  it 'does not allow same rank within a counting and sample' do
    @occurrence_repo.expect(:rank_exists_within_counting_and_sample?, true, [1, 200, 300])
    result = @contract.call(rank: 1, counting_id: 200, sample_id: 300)
    assert(result.error?(:rank))
    assert(result.errors[:rank].include?('is already taken'))
  end

  it 'allows different ranks within a counting and sample' do
    @occurrence_repo.expect(:rank_exists_within_counting_and_sample?, false, [1, 200, 300])
    result = @contract.call(rank: 1, counting_id: 200, sample_id: 300)
    refute(result.error?(:rank))
  end

  it 'does not allow same species within a counting and sample' do
    @occurrence_repo.expect(:species_exists_within_counting_and_sample?, true, [100, 200, 300])
    result = @contract.call(species_id: 100, counting_id: 200, sample_id: 300)
    assert(result.error?(:species_id))
    assert(result.errors[:species_id].include?('is already taken'))
  end

  it 'allows different ranks within a counting and sample' do
    @occurrence_repo.expect(:species_exists_within_counting_and_sample?, false, [100, 200, 300])
    result = @contract.call(species_id: 100, counting_id: 200, sample_id: 300)
    refute(result.error?(:species_id))
  end

  it 'accepts valid statuses' do
    [
      Paleolog::CountingSummary::NORMAL,
      Paleolog::CountingSummary::OUTSIDE_COUNT,
      Paleolog::CountingSummary::CARVING,
      Paleolog::CountingSummary::REWORKING
    ].each do |value|
      result = @schema.call(status: value)
      refute(result.error?(:status))
    end
  end

  it 'requires status' do
    assert_requires_integer(@schema, :status)
	end

  it 'refutes invalid statuese' do
    [-100, -1, 4, 5, 100].each do |value|
      result = @schema.call(status: value)
      assert(result.error?(:status))
    end
  end
end
