# frozen_string_literal: true

require 'test_helper'
require_relative './common_assertions'

describe Paleolog::Contract::Project do
  include CommonAssertions

  before do
    @schema = Paleolog::Contract::ProjectSchema
    @project_repo = MiniTest::Mock.new
    @contract = Paleolog::Contract::Project.new(project_repo: @project_repo)
  end

  it 'validates name' do
    assert_requires_string(@schema, :name)
    assert_strips_string(@schema, :name)
    assert_restricts_string_length(@schema, :name, max: 255)
  end

  it 'does not complain when name not taken yet' do
    @project_repo.expect(:name_exists?, false, ['Project Name'])
    refute(@contract.call(name: 'Project Name').error?(:name))
    @project_repo.verify
  end

  it 'complains when name already exists' do
    @project_repo.expect(:name_exists?, true, ['Project Name'])
    result = @contract.call(name: 'Project Name')
    assert(result.errors[:name].include?('is already taken'))
    @project_repo.verify
  end
end
