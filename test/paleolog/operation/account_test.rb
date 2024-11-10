# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Account do
  let(:repo) { Paleolog::Repo }
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) { Paleolog::Operation::Account.new(repo, authorizer) }
  let(:happy_operation) { happy_operation_for(Paleolog::Operation::Account, user) }
  let(:user) { repo.find(Paleolog::User, repo.save(Paleolog::User.new(login: 'test', password: 'test123'))) }

  after do
    repo.for(Paleolog::Account).delete_all
    repo.for(Paleolog::User).delete_all
  end

  describe '#create' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.create(name: 'Just a Name')
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    describe 'for authenticated user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :user_id, user.id
      end

      it 'adds new account' do
        result = operation.create(name: 'Some Name')
        assert_predicate result, :success?
        refute_nil result.value
      end

      it 'complains when name is nil' do
        result = operation.create({ name: nil })
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create({ name: '  ' })
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create({ name: 'Some Name' })
        assert_predicate result, :success?

        result = operation.create({ name: 'Some Name' })
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end
    end
  end

  describe '#update' do
    let(:account) do
      happy_operation.create({ name: 'Some Name' }).value
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.update({ id: account.id, name: 'Just Another Name' })
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Account, account.id]

      result = operation.update({ id: account.id, name: 'Just Another Name' })
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHORIZED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Account, account.id]
      end

      it 'updates account' do
        result = operation.update(id: account.id, name: 'Other Name')
        assert_predicate result, :success?
        assert_equal 'Other Name', result.value.name
      end

      it 'can set the same name' do
        result = operation.update(id: account.id, name: 'Some Name')
        assert_predicate result, :success?
        assert_equal 'Some Name', result.value.name
      end

      it 'complains when name is nil' do
        result = operation.update(id: account.id, name: nil)
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.update(id: account.id, name: '   ')
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Other Name')
        assert_predicate result, :success?

        result = operation.update(id: account.id, name: 'Other Name')
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(name: 'Other Name')
        assert_predicate result, :success?

        result = operation.update(id: account.id, name: ' other name ')
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end
    end
  end
end
