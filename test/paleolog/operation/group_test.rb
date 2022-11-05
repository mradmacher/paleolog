# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Group do
  let(:operation) { Paleolog::Operation::Group }

  after do
    Paleolog::Repo::Group.delete_all
  end

  describe '#create' do
    it 'does not complain when name not taken yet' do
      result = operation.create(name: 'Some Name')
      assert result.success?

      result = operation.create(name: 'Other Name')
      assert result.success?
    end

    it 'complains when name is blank' do
      result = operation.create(name: nil)
      assert result.failure?
      assert_equal :blank, result.error[:name]

      result = operation.create(name: '  ')
      assert result.failure?
      assert_equal :blank, result.error[:name]
    end

    it 'complains when name already exists' do
      result = operation.create(name: 'Some Name')
      assert result.success?

      result = operation.create(name: 'Some Name')
      assert result.failure?
      assert_equal :taken, result.error[:name]
    end

    it 'complains when name is too long' do
      max = 255
      result = operation.create(name: 'a' * (max + 1))
      assert result.failure?
      assert_equal :too_long, result.error[:name]

      result = operation.create(name: 'a' * max)
      assert result.success?
    end

    it 'complains when name with different cases already exists' do
      result = operation.create(name: 'Some Name')
      assert result.success?

      result = operation.create(name: ' some name ')
      assert result.failure?
      assert_equal :taken, result.error[:name]
    end
  end
end
