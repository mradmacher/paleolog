# frozen_string_literal: true

require 'web_helper'

describe 'Projects' do
  include Rack::Test::Methods

  let(:project) { Paleolog::Project.new(id: 1, name: 'some project', created_at: Time.now) }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:session) { {} }
  let(:app) { Web::Api::Projects.new }
  let(:operation) { Minitest::Mock.new }

  before do
    Web::Api::Projects.set :operation, operation
  end

  after do
    Paleolog::Repo::User.delete_all
  end

  describe 'GET /api/projects' do
    it 'rejects guest access' do
      assert_unauthorized(-> { get '/api/projects', {} })
    end

    it 'accepts logged in user' do
      operation.expect :find_all_for_user, [], [user.id]
      login(user)
      assert_permitted(-> { get '/api/projects', {} })
    end

    describe 'with user' do
      before do
        login(user)
      end

      it 'returns empty collection' do
        operation.expect :find_all_for_user, [], [user.id]

        get '/api/projects'
        assert_predicate last_response, :ok?, "Expected 200, but got #{last_response.status}"
        response_body = JSON.parse(last_response.body)
        assert_empty response_body['projects']
      end

      it 'returns many projects' do
        other_project = Paleolog::Project.new(id: 2, name: 'project1')
        operation.expect :find_all_for_user, [project, other_project], [user.id]

        get '/api/projects'
        result = JSON.parse(last_response.body)['projects']
        assert_equal 2, result.size
        assert_equal([project.id, other_project.id], result.map { |r| r['id'] })
      end

      it 'returns all necessary attributes' do
        operation.expect :find_all_for_user, [project], [user.id]
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
      operation.expect :create, [project, {}], [{ 'name' => 'some name', 'user_id' => user.id }]
      login(user)
      assert_permitted(-> { post '/api/projects', params })
    end

    describe 'with user' do
      before do
        login(user)
      end

      it 'creates project and returns its attributes' do
        params = { name: 'some name' }
        operation.expect :create, [project, {}], [{ 'name' => 'some name', 'user_id' => user.id }]
        post '/api/projects', params

        result = JSON.parse(last_response.body)['project']

        assert_equal project.id, result['id']
        assert_equal project.name, result['name']
        assert_equal project.created_at.to_s, result['created_at']
      end

      it 'returns errors in case of failure' do
        params = {}
        operation.expect :create, [nil, { name: 'missing' }], [{ 'user_id' => user.id }]
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
      assert_forbidden(-> { patch '/api/projects/1', {} })
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: true))
        login(user)
      end

      it 'updates project name and returns its attributes' do
        params = { name: 'some other name' }
        operation.expect :rename, [project, {}], ['1'], name: 'some other name'
        patch '/api/projects/1', params

        result = JSON.parse(last_response.body)['project']

        assert_equal 1, result['id']
        assert_equal project.name, result['name']
        assert_equal project.created_at.to_s, result['created_at']
      end

      it 'returns errors in case of failure' do
        params = {}
        operation.expect :rename, [nil, { name: 'missing' }], ['1'], name: nil
        patch '/api/projects/1', params

        result = JSON.parse(last_response.body)
        assert result.key?('errors')

        assert_equal 'missing', result['errors']['name']
      end
    end
  end
end
