# frozen_string_literal: true

require 'web_helper'

describe 'Projects' do
  include Rack::Test::Methods

  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:project) do
    project, errors = Paleolog::Operation::Project.create({ name: 'some test project' }, user_id: user.id)
    assert_predicate errors, :empty?
    project
  end
  let(:app) { Web::Api::Projects.new }

  before do
    project
  end

  after do
    Paleolog::Repo::ResearchParticipation.delete_all
    Paleolog::Repo::Project.delete_all
    Paleolog::Repo::User.delete_all
  end

  describe 'GET /api/projects' do
    it 'rejects guest access' do
      assert_unauthorized(-> { get '/api/projects', {} })
    end

    it 'accepts logged in user' do
      login(user)
      assert_permitted(-> { get '/api/projects', {} })
    end

    describe 'with user' do
      before do
        login(user)
      end

      it 'returns empty collection when user has no projects' do
        Paleolog::Repo::ResearchParticipation.delete_all
        Paleolog::Repo::Project.delete_all
        get '/api/projects'
        assert_predicate last_response, :ok?, "Expected 200, but got #{last_response.status}"
        response_body = JSON.parse(last_response.body)
        assert_empty response_body['projects']
      end

      it 'returns many projects' do
        other_project, = Paleolog::Operation::Project.create({ name: 'project1' }, user_id: user.id)

        get '/api/projects'
        result = JSON.parse(last_response.body)['projects']
        assert_equal 2, result.size
        assert_equal([project.id, other_project.id], result.map { |r| r['id'] })
      end

      it 'returns all necessary attributes' do
        get '/api/projects'
        result = JSON.parse(last_response.body)['projects']

        assert_equal 1, result.size
        result = result.first
        assert_equal project.id, result['id']
        assert_equal project.name, result['name']
        assert_equal project.created_at.to_s, result['created_at']
      end
    end
  end

  describe 'POST /api/projects' do
    it 'rejects guest access' do
      assert_unauthorized(-> { post '/api/projects', {} })
    end

    it 'accepts logged in user' do
      params = { name: 'some name' }
      login(user)
      assert_permitted(-> { post '/api/projects', params })
    end

    describe 'with user' do
      before do
        login(user)
      end

      it 'creates project and returns its attributes' do
        params = { name: 'some name' }
        post '/api/projects', params

        result = JSON.parse(last_response.body)['project']

        refute_nil result['id']
        assert_equal 'some name', result['name']
        refute_nil result['created_at']
      end

      it 'returns errors in case of failure' do
        params = {}
        post '/api/projects', params

        result = JSON.parse(last_response.body)
        assert result.key?('errors')

        assert_equal 'missing', result['errors']['name']
      end
    end
  end

  describe 'PATCH /api/projects/:id' do
    it 'rejects guest access' do
      assert_unauthorized(-> { patch '/api/projects/1', {} })
    end

    it 'rejects user observing the project' do
      Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: false))
      login(user)
      assert_forbidden(-> { patch '/api/projects/1', { name: 'some name' } })
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: true))
        login(user)
      end

      it 'updates project name and returns its attributes' do
        params = { name: 'some other name' }
        patch "/api/projects/#{project.id}", params

        result = JSON.parse(last_response.body)['project']

        assert_equal project.id, result['id']
        assert_equal 'some other name', result['name']
        assert_equal project.created_at.to_s, result['created_at']
      end

      it 'returns errors in case of failure' do
        params = {}
        patch '/api/projects/1', params

        result = JSON.parse(last_response.body)
        assert result.key?('errors')

        assert_equal 'missing', result['errors']['name']
      end
    end
  end
end
