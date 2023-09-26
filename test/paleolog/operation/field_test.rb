# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Field do
  let(:repo) { Paleolog::Repo }
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) do
    Paleolog::Operation::Field.new(repo, authorizer)
  end
  let(:group) do
    Paleolog::Operation::Group.new(repo, HappyAuthorizer.new(user)).create(
      name: 'Group for Field',
    ).value
  end
  let(:user) { repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }

  after do
    repo.for(Paleolog::Group).delete_all
    repo.for(Paleolog::Field).delete_all
  end

  describe '#create' do
    it 'does not complain when name not taken yet' do
      result = operation.create(name: 'Some Name', group_id: group.id)
      assert_predicate result, :success?

      result = operation.create(name: 'Other Name', group_id: group.id)
      assert_predicate result, :success?
    end

    it 'complains when group_id blank' do
      result = operation.create(name: 'Name', group_id: nil)
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:group_id]

      result = operation.create(name: 'Name', group_id: Optiomist.none)
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::Params::MISSING, result.error[:group_id]
    end

    it 'complains when name is blank' do
      result = operation.create(name: nil, group_id: group.id)
      assert_predicate result, :failure?
      assert_equal :blank, result.error[:name]

      result = operation.create(name: '  ', group_id: group.id)
      assert_predicate result, :failure?
      assert_equal :blank, result.error[:name]
    end

    it 'complains when name already exists' do
      result = operation.create(name: 'Some Name', group_id: group.id)
      assert_predicate result, :success?

      result = operation.create(name: 'Some Name', group_id: group.id)
      assert_predicate result, :failure?
      assert_equal :taken, result.error[:name]
    end

    it 'complains when name is too long' do
      max = 255
      result = operation.create(name: 'a' * (max + 1), group_id: group.id)
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:name]

      result = operation.create(name: 'a' * max, group_id: group.id)
      assert_predicate result, :success?
    end

    it 'complains when name with different cases already exists' do
      result = operation.create(name: 'Some Name', group_id: group.id)
      assert_predicate result, :success?

      result = operation.create(name: ' some name ', group_id: group.id)
      assert_predicate result, :failure?
      assert_equal :taken, result.error[:name]
    end
  end
end
