# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repository::User do
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) { Paleolog::Repository::User.new(Paleolog.db, authorizer) }

  describe '#find' do
    it 'returns user for given login' do
      result = operation.create(login: 'login1', password: 'p1')

      assert_predicate result, :success?

      result = operation.find(login: 'login2')

      assert_predicate result, :failure?
      assert Paleolog::Operation.not_found?(result.error)

      result = operation.find(login: 'login1')

      assert_predicate result, :success?
      assert_equal 'login1', result.value.login
    end
  end
end
