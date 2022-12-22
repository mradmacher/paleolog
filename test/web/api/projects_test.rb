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
      refute_guest_access(-> { get '/api/projects', {} })
    end

    it 'accepts logged in user' do
      operation.expect :find_all_for_user, [], [user.id]
      assert_user_access(-> { get '/api/projects', {} }, user)
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
        assert_equal [project.id, other_project.id], result.map { |r| r['id'] }
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
      params = { name: 'some name' }
      refute_guest_access(-> { post '/api/projects', {} })
    end

    it 'accepts logged in user' do
      params = { name: 'some name' }
      operation.expect :create, Success.new(project), [{ 'name' => 'some name', 'user_id' => user.id }]
      assert_user_access(-> { post '/api/projects', params }, user)
    end

    describe 'with user' do
      before do
        login(user)
      end

      it 'creates project and returns its attributes' do
        params = { name: 'some name' }
        operation.expect :create, Success.new(project), [{ 'name' => 'some name', 'user_id' => user.id }]
        post '/api/projects', params

        result = JSON.parse(last_response.body)['project']

        assert_equal project.id, result['id']
        assert_equal project.name, result['name']
        assert_equal project.created_at.to_s, result['created_at']
      end

      it 'returns errors in case of failure' do
        params = {}
        operation.expect :create, Failure.new({ name: 'missing' }), [{ 'user_id' => user.id }]
        post '/api/projects', params

        result = JSON.parse(last_response.body)
        assert result.key?('errors')

        assert_equal 'missing', result['errors']['name']
      end
    end
  end
end
