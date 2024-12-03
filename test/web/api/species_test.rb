# frozen_string_literal: true

require 'web_helper'

describe 'Projects' do
  include Rack::Test::Methods

  let(:repo) { Paleolog::Repo }
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end
  let(:happy_operation) { happy_operation_for(Paleolog::Repository::Species, user) }
  let(:group1) do
    happy_operation_for(Paleolog::Repository::Group, user)
      .create(name: 'Dinoflagellate').value
  end
  let(:group2) do
    happy_operation_for(Paleolog::Repository::Group, user)
      .create(name: 'Other').value
  end
  let(:app) { Web::Api::Species.new }

  describe 'GET /api/species' do
    it 'rejects guest access' do
      assert_unauthorized(-> { get '/api/species', {} })
    end

    it 'accepts logged in user' do
      login(user)

      assert_permitted(-> { get '/api/species', {} })
    end
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

      it 'works' do
        get '/api/species', {}

        assert_predicate last_response, :ok?
        result = JSON.parse(last_response.body)['species']

        refute_nil result
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

      it 'updates species name and returns its attributes' do
        params = { name: 'some other name' }
        patch "/api/species/#{species.id}", params

        result = JSON.parse(last_response.body)['species']

        assert_equal species.id, result['id']
        assert_equal 'some other name', result['name']
        assert_equal species.created_at.to_s, result['created_at']
      end

      it 'returns errors in case of failure' do
        params = { name: '' }
        patch '/api/species/1', params

        result = JSON.parse(last_response.body)

        assert result.key?('errors')

        assert_equal 'blank', result['errors']['name']
      end
    end
  end
end
