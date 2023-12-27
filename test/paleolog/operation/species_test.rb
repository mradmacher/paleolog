# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Species do
  let(:repo) { Paleolog::Repo }
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) { Paleolog::Operation::Species.new(repo, authorizer) }
  let(:happy_operation) { happy_operation_for(Paleolog::Operation::Species, user) }
  let(:group_id) { happy_operation_for(Paleolog::Operation::Group, user).create(name: 'A Group').value }
  let(:user) do
    repo.find(
      Paleolog::User,
      repo.save(Paleolog::User.new(login: 'test', password: 'test123')),
    )
  end
  after do
    repo.for(Paleolog::Species).delete_all
    repo.for(Paleolog::Group).delete_all
  end

  describe '#update' do
    let(:species_id) do
      happy_operation.create({ name: 'Some Name', group_id: group_id }).value
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.update(id: species_id, name: 'Just a Name')
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'complains when group_id blank' do
        result = operation.update(id: species_id, group_id: nil)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:group_id]
      end

      it 'can set the same name' do
        result = operation.update(id: species_id, name: 'Some Name')
        assert_predicate result, :success?
        assert_equal 'Some Name', repo.find(Paleolog::Species, result.value).name
      end

      it 'does not complain when name not taken yet' do
        result = operation.update(id: species_id, name: 'Some Other Name')
        assert_predicate result, :success?
      end

      it 'complains when name is nil' do
        result = operation.update(id: species_id, name: nil)
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.update(id: species_id, name: '  ')
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Some Other Name', group_id: group_id)
        assert_predicate result, :success?

        result = operation.update(id: species_id, name: 'Some Other Name')
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.update(id: species_id, name: 'a' * (max + 1))
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:name]
      end

      it 'does not complain when name is max length' do
        max = 255
        result = operation.create(id: species_id, group_id: group_id, name: 'a' * max)
        assert_predicate result, :success?
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(name: 'Some Other Name', group_id: group_id)
        assert_predicate result, :success?

        result = operation.update(id: species_id, name: ' some OTHER name ')
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'requires description length to be less than 4096 characters' do
        description = 'a' * (4096 + 1)
        result = operation.update(id: species_id, description: description)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:description]
      end

      it 'allows description length to be equal to 4096 characters' do
        description = 'a' * 4096
        result = operation.update(id: species_id, group_id: group_id, description: description)
        assert_predicate result, :success?
      end

      it 'requires environmental preferences length to be less than 4096 characters' do
        environmental_preferences = 'a' * (4096 + 1)
        result = operation.update(id: species_id, environmental_preferences: environmental_preferences)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:environmental_preferences]
      end

      it 'allows environmental preferences length to be equal to 4096 characters' do
        environmental_preferences = 'a' * 4096
        result = operation.update(id: species_id, environmental_preferences: environmental_preferences)
        assert_predicate result, :success?
      end
    end
  end

  describe '#create' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.create(name: 'Just a Name')
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'does not complain when name not taken yet' do
        result = operation.create(name: 'Some Name', group_id: group_id)
        assert_predicate result, :success?
      end

      it 'complains when group_id blank' do
        result = operation.create(name: 'Name', group_id: nil)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:group_id]
      end

      it 'complains when group_id missing' do
        result = operation.create(name: 'Name')
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::MISSING, result.error[:group_id]
      end

      it 'complains when name is nil' do
        result = operation.create(name: nil, group_id: group_id)
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create(name: '  ', group_id: group_id)
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Some Name', group_id: group_id)
        assert_predicate result, :success?

        result = operation.create(name: 'Some Name', group_id: group_id)
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.create(
          { name: 'a' * (max + 1), group_id: group_id },
        )
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:name]
      end

      it 'does not complain when name is max length' do
        max = 255
        result = operation.create(name: 'a' * max, group_id: group_id)
        assert_predicate result, :success?
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(
          { name: 'Some Name', group_id: group_id },
        )
        assert_predicate result, :success?

        result = operation.create(
          { name: ' some name ', group_id: group_id },
        )
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'requires description length to be less than 4096 characters' do
        description = 'a' * (4096 + 1)
        result = operation.create(
          { group_id: group_id, name: 'Name', description: description },
        )
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:description]
      end

      it 'allows description length to be equal to 4096 characters' do
        description = 'a' * 4096
        result = operation.create(
          { group_id: group_id, name: 'Name', description: description },
        )
        assert_predicate result, :success?
      end

      it 'requires environmental preferences length to be less than 4096 characters' do
        environmental_preferences = 'a' * (4096 + 1)
        result = operation.create(
          { group_id: group_id, name: 'Name', environmental_preferences: environmental_preferences },
        )
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:environmental_preferences]
      end

      it 'allows environmental preferences length to be equal to 4096 characters' do
        environmental_preferences = 'a' * 4096
        result = operation.create(
          { group_id: group_id, name: 'Name', environmental_preferences: environmental_preferences },
        )
        assert_predicate result, :success?
      end
    end
  end
end
