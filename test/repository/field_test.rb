# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repository::Field do
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) { Paleolog::Repository::Field.new(Paleolog.db, authorizer) }
  let(:group) do
    happy_operation_for(Paleolog::Repository::Group, user).create(
      name: 'Group for Field',
    ).value
  end
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end

  describe '#find_all' do
    it 'returns all fields' do
      operation.create(name: 'Field1', group_id: group.id)
               .and_then { operation.create(name: 'Field2', group_id: group.id) }
               .and_then { operation.find_all }
               .on_failure { |error| flunk "Expected success, got #{error}" }
               .on_success do |fields|
        assert_equal %w[Field1 Field2], fields.map(&:name)
      end
    end

    it 'loads all related choices' do
      operation.create(name: 'Field1', group_id: group.id)
               .on_success do |field|
        operation.add_choice(name: 'C1', field_id: field.id)
        operation.add_choice(name: 'C2', field_id: field.id)
      end
        .and_then { operation.find_all }
               .on_failure { |error| flunk "Expected success, got #{error}" }
               .on_success do |fields|
        assert_equal(%w[C1 C2], fields.first.choices.map(&:name))
      end
    end
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
      assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:group_id]

      result = operation.create(name: 'Name', group_id: Optiomist.none)

      assert_predicate result, :failure?
      assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:group_id]
    end

    it 'complains when name is blank' do
      result = operation.create(name: nil, group_id: group.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]

      result = operation.create(name: '  ', group_id: group.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]
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
      assert_equal Paleolog::Repository::Params::TOO_LONG_ERR, result.error[:name]

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

  describe '#add_choice' do
    let(:field) do
      happy_operation_for(Paleolog::Repository::Field, user).create(
        name: 'Field for Choice', group_id: group.id,
      ).value
    end

    it 'creates a new choice' do
      result = operation.add_choice(name: 'Some Name', field_id: field.id)

      assert_predicate result, :success?

      result = operation.add_choice(name: 'Other Name', field_id: field.id)

      assert_predicate result, :success?
    end

    it 'complains when field_id blank' do
      result = operation.add_choice(name: 'Name', field_id: nil)

      assert_predicate result, :failure?
      assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:field_id]

      result = operation.add_choice(name: 'Name', field_id: Optiomist.none)

      assert_predicate result, :failure?
      assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:field_id]
    end

    it 'complains when name is blank' do
      result = operation.add_choice(name: nil, field_id: field.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]

      result = operation.add_choice(name: '  ', field_id: field.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]
    end

    it 'complains when name already exists' do
      result = operation.add_choice(name: 'Some Name', field_id: field.id)

      assert_predicate result, :success?

      result = operation.add_choice(name: 'Some Name', field_id: field.id)

      assert_predicate result, :failure?
      assert_equal :taken, result.error[:name]
    end

    it 'complains when name is too long' do
      max = 255
      result = operation.add_choice(name: 'a' * (max + 1), field_id: field.id)

      assert_predicate result, :failure?
      assert_equal :too_long, result.error[:name]

      result = operation.add_choice(name: 'a' * max, field_id: field.id)

      assert_predicate result, :success?
    end

    it 'complains when name with different cases already exists' do
      result = operation.add_choice(name: 'Some Name', field_id: field.id)

      assert_predicate result, :success?

      result = operation.add_choice(name: ' some name ', field_id: field.id)

      assert_predicate result, :failure?
      assert_equal :taken, result.error[:name]
    end
  end
end
