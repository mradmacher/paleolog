# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Choice do
  let(:operation) { Paleolog::Operation::Choice }
  let(:group) { Paleolog::Operation::Group.create(name: 'Group for Field').value }
  let(:field) { Paleolog::Operation::Field.create(name: 'Field for Choice', group_id: group.id).value }

  after do
    Paleolog::Repo::Group.delete_all
    Paleolog::Repo::Field.delete_all
    Paleolog::Repo::Choice.delete_all
  end

  describe '#create' do
    it 'does not complain when name not taken yet' do
      result = operation.create(name: 'Some Name', field_id: field.id)
      assert result.success?

      result = operation.create(name: 'Other Name', field_id: field.id)
      assert result.success?
    end

    it 'complains when field_id blank' do
      result = operation.create(name: 'Name', field_id: nil)
      assert result.failure?
      assert_equal ParamParam::NON_INTEGER, result.error[:field_id]

      result = operation.create(name: 'Name', field_id: ParamParam::Option.None)
      assert result.failure?
      assert_equal :missing, result.error[:field_id]
    end

    it 'complains when name is blank' do
      result = operation.create(name: nil, field_id: field.id)
      assert result.failure?
      assert_equal :blank, result.error[:name]

      result = operation.create(name: '  ', field_id: field.id)
      assert result.failure?
      assert_equal :blank, result.error[:name]
    end

    it 'complains when name already exists' do
      result = operation.create(name: 'Some Name', field_id: field.id)
      assert result.success?

      result = operation.create(name: 'Some Name', field_id: field.id)
      assert result.failure?
      assert_equal :taken, result.error[:name]
    end

    it 'complains when name is too long' do
      max = 255
      result = operation.create(name: 'a' * (max + 1), field_id: field.id)
      assert result.failure?
      assert_equal :too_long, result.error[:name]

      result = operation.create(name: 'a' * max, field_id: field.id)
      assert result.success?
    end

    it 'complains when name with different cases already exists' do
      result = operation.create(name: 'Some Name', field_id: field.id)
      assert result.success?

      result = operation.create(name: ' some name ', field_id: field.id)
      assert result.failure?
      assert_equal :taken, result.error[:name]
    end
  end
end
