# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Species do
  let(:operation) { Paleolog::Operation::Species }
  let(:group) { Paleolog::Operation::Group.create(name: 'A Group').value }
  let(:authorizer) { Minitest::Mock.new }

  after do
    Paleolog::Repo::Species.delete_all
    Paleolog::Repo::Group.delete_all
  end

  describe '#create' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.create({ name: 'Just a Name' }, authorizer: authorizer)
      refute_predicate result, :success?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'does not complain when name not taken yet' do
        result = operation.create(
          { name: 'Some Name', group_id: group.id },
          authorizer: authorizer,
        )
        assert_predicate result, :success?
      end

      it 'complains when group_id blank' do
        result = operation.create(
          {name: 'Name', group_id: nil},
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::NON_INTEGER, result.error[:group_id]
      end

      it 'complains when group_id none' do
        result = operation.create(
          { name: 'Name', group_id: ParamParam::Option.None },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::MISSING, result.error[:group_id]
      end

      it 'complains when name is nil' do
        result = operation.create(
          { name: nil, group_id: group.id },
          authorizer: authorizer
        )
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create(
          { name: '  ', group_id: group.id },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = operation.create(
          { name: 'Some Name', group_id: group.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_predicate result, :success?

        result = operation.create(
          { name: 'Some Name', group_id: group.id },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.create(
          { name: 'a' * (max + 1), group_id: group.id },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::TOO_LONG, result.error[:name]
      end

      it 'does not complain when name is max length' do
        max = 255
        result = operation.create(
          { name: 'a' * max, group_id: group.id },
          authorizer: authorizer,
        )
        assert_predicate result, :success?
      end

      it 'complains when name with different cases already exists' do
        result = operation.create(
          { name: 'Some Name', group_id: group.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_predicate result, :success?

        result = operation.create(
          { name: ' some name ', group_id: group.id },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'requires description length to be less than 4096 characters' do
        description = 'a' * (4096 + 1)
        result = operation.create(
          { group_id: group.id, name: 'Name', description: description },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::TOO_LONG, result.error[:description]
      end

      it 'allows description length to be equal to 4096 characters' do
        description = 'a' * 4096
        result = operation.create(
          { group_id: group.id, name: 'Name', description: description },
          authorizer: authorizer,
        )
        assert_predicate result, :success?
      end

      it 'requires environmental preferences length to be less than 4096 characters' do
        environmental_preferences = 'a' * (4096 + 1)
        result = operation.create(
          { group_id: group.id, name: 'Name', environmental_preferences: environmental_preferences },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::TOO_LONG, result.error[:environmental_preferences]
      end

      it 'allows environmental preferences length to be equal to 4096 characters' do
        environmental_preferences = 'a' * 4096
        result = operation.create(
          { group_id: group.id, name: 'Name', environmental_preferences: environmental_preferences },
          authorizer: authorizer,
        )
        assert_predicate result, :success?
      end
    end
  end
end
