# frozen_string_literal: true

require 'test_helper'
require_relative './common_assertions'

describe Paleolog::Contract::Section do
  include CommonAssertions

  before do
    @schema = Paleolog::Contract::SectionSchema
    @section_repo = MiniTest::Mock.new
    @contract = Paleolog::Contract::Section.new(section_repo: @section_repo)
  end

  it 'validates name' do
    assert_requires_string(@schema, :name)
    assert_strips_string(@schema, :name)
    assert_restricts_string_length(@schema, :name, max: 255)
  end

  it 'requires project id' do
    assert_requires_integer(@schema, :project_id)
    assert_performs_integer_coertion(@schema, :project_id)
  end

  it 'does not complain when name not taken yet' do
    @section_repo.expect(:name_exists_within_project?, false, ['Name', 1])
    refute(@contract.call(name: 'Name', project_id: 1).error?(:name))
    @section_repo.verify
  end

  it 'complains when name already exists' do
    @section_repo.expect(:name_exists_within_project?, true, ['Name', 1])
    result = @contract.call(name: 'Name', project_id: 1)
    assert(result.errors[:name].include?('is already taken'))
    @section_repo.verify
  end
end
