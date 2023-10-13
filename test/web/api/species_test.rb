# frozen_string_literal: true

require 'web_helper'

describe 'Projects' do
  include Rack::Test::Methods

  let(:repo) { Paleolog::Repo }
  let(:user) { repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:happy_operation) { Paleolog::Operation::Species.new(repo, HappyAuthorizer.new(user)) }
  let(:group1) { repo.save(Paleolog::Group.new(name: 'Dinoflagellate')) }
  let(:group2) { repo.save(Paleolog::Group.new(name: 'Other')) }
  let(:app) { Web::Api::Species.new }

  after do
    repo.for(Paleolog::Species).delete_all
    repo.for(Paleolog::User).delete_all
    repo.for(Paleolog::Group).delete_all
  end

  describe 'POST /api/species' do
    it 'rejects guest access' do
      assert_unauthorized(-> { post '/api/species', {} })
    end

    it 'accepts logged in user' do
      params = { name: 'some name', group_id: group1.id }
      login(user)
      assert_permitted(-> { post '/api/species', params })
    end

    describe 'with user' do
      before do
        login(user)
      end

      it 'creates project and returns its attributes' do
        params = { name: 'some name', group_id: group1.id }
        post '/api/species', params

        result = JSON.parse(last_response.body)['species']

        refute_nil result['id']
        assert_equal 'some name', result['name']
        assert_equal group1.id, result['group_id']
        refute_nil result['created_at']
      end

      it 'returns errors in case of failure' do
        params = {}
        post '/api/species', params

        result = JSON.parse(last_response.body)
        assert result.key?('errors')

        assert_equal 'missing', result['errors']['name']
      end
    end
  end

  describe 'PATCH /api/species/:id' do
    let(:species) do
      result = happy_operation.create(name: 'some test species', group_id: group1.id)
      assert_predicate result, :success?
      result.value
    end

    it 'rejects guest access' do
      assert_unauthorized(-> { patch '/api/species/1', {} })
    end

    describe 'with user' do
      before do
        login(user)
      end

      it 'updates project name and returns its attributes' do
        params = { name: 'some other name' }
        patch "/api/species/#{species.id}", params

        result = JSON.parse(last_response.body)['species']

        assert_equal project.id, result['id']
        assert_equal 'some other name', result['name']
        assert_equal project.created_at.to_s, result['created_at']
      end

      it 'returns errors in case of failure' do
        params = {}
        patch '/api/species/1', params

        result = JSON.parse(last_response.body)
        assert result.key?('errors')

        assert_equal 'missing', result['errors']['name']
      end
    end
  end
end
