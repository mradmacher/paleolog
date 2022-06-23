# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::User do
  let(:repo) { Paleolog::Repo::User }

  after do
    repo.delete_all
  end

  describe '#find_by_login' do
    it 'returns user for given login' do
      Paleolog::Repo.save(Paleolog::User.new(login: 'login1', password: 'p1'))

      assert_nil(repo.find_by_login('login2'))
      assert_equal('login1', repo.find_by_login('login1').login)
    end
  end
end
