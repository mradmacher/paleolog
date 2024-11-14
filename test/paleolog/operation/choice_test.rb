# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Choice do
  let(:repo) { Paleolog::Repo }
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) do
    Paleolog::Operation::Choice.new(repo, authorizer)
  end
  let(:group) do
    happy_operation_for(Paleolog::Operation::Group, user).create(
      name: 'Group for Field',
    ).value
  end
  let(:field) do
    happy_operation_for(Paleolog::Operation::Field, user).create(
      name: 'Field for Choice', group_id: group.id,
    ).value
  end
  let(:user) do
    repo.find(
      Paleolog::User,
      repo.save(Paleolog::User.new(login: 'test', password: 'test123')),
    )
  end

  describe '#create' do
    it 'does not complain when name not taken yet' do
      result = operation.create(name: 'Some Name', field_id: field.id)

      assert_predicate result, :success?

      result = operation.create(name: 'Other Name', field_id: field.id)

      assert_predicate result, :success?
    end

    it 'complains when field_id blank' do
      result = operation.create(name: 'Name', field_id: nil)

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:field_id]

      result = operation.create(name: 'Name', field_id: Optiomist.none)

      assert_predicate result, :failure?
      assert_equal :missing, result.error[:field_id]
    end

    it 'complains when name is blank' do
      result = operation.create(name: nil, field_id: field.id)

      assert_predicate result, :failure?
      assert_equal :blank, result.error[:name]

      result = operation.create(name: '  ', field_id: field.id)

      assert_predicate result, :failure?
      assert_equal :blank, result.error[:name]
    end

    it 'complains when name already exists' do
      result = operation.create(name: 'Some Name', field_id: field.id)

      assert_predicate result, :success?

      result = operation.create(name: 'Some Name', field_id: field.id)

      assert_predicate result, :failure?
      assert_equal :taken, result.error[:name]
    end

    it 'complains when name is too long' do
      max = 255
      result = operation.create(name: 'a' * (max + 1), field_id: field.id)

      assert_predicate result, :failure?
      assert_equal :too_long, result.error[:name]

      result = operation.create(name: 'a' * max, field_id: field.id)

      assert_predicate result, :success?
    end

    it 'complains when name with different cases already exists' do
      result = operation.create(name: 'Some Name', field_id: field.id)

      assert_predicate result, :success?

      result = operation.create(name: ' some name ', field_id: field.id)

      assert_predicate result, :failure?
      assert_equal :taken, result.error[:name]
    end
  end
end
