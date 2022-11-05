# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Field do
  let(:operation) { Paleolog::Operation::Field }
  let(:group) { Paleolog::Operation::Group.create(name: 'Group for Field').value }

  after do
    Paleolog::Repo::Group.delete_all
    Paleolog::Repo::Field.delete_all
  end

  describe '#create' do
    it 'does not complain when name not taken yet' do
      result = operation.create(name: 'Some Name', group_id: group.id)
      assert result.success?

      result = operation.create(name: 'Other Name', group_id: group.id)
      assert result.success?
    end

    it 'complains when group_id blank' do
      result = operation.create(name: 'Name', group_id: nil)
      assert result.failure?
      assert_equal :noninteger, result.error[:group_id]

      result = operation.create(name: 'Name', group_id: Option.None)
      assert result.failure?
      assert_equal :missing, result.error[:group_id]
    end

    it 'complains when name is blank' do
      result = operation.create(name: nil, group_id: group.id)
      assert result.failure?
      assert_equal :blank, result.error[:name]

      result = operation.create(name: '  ', group_id: group.id)
      assert result.failure?
      assert_equal :blank, result.error[:name]
    end

    it 'complains when name already exists' do
      result = operation.create(name: 'Some Name', group_id: group.id)
      assert result.success?

      result = operation.create(name: 'Some Name', group_id: group.id)
      assert result.failure?
      assert_equal :taken, result.error[:name]
    end

    it 'complains when name is too long' do
      max = 255
      result = operation.create(name: 'a' * (max + 1), group_id: group.id)
      assert result.failure?
      assert_equal :too_long, result.error[:name]

      result = operation.create(name: 'a' * max, group_id: group.id)
      assert result.success?
    end

    it 'complains when name with different cases already exists' do
      result = operation.create(name: 'Some Name', group_id: group.id)
      assert result.success?

      result = operation.create(name: ' some name ', group_id: group.id)
      assert result.failure?
      assert_equal :taken, result.error[:name]
    end
  end
end
