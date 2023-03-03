# frozen_string_literal: true

require 'web_helper'

describe 'Sections' do
  include Rack::Test::Methods

  let(:project) { Paleolog::Project.new(id: 10, name: 'some project', created_at: Time.now) }
  let(:section) { Paleolog::Section.new(id: 1, name: 'some section', project: project, created_at: Time.now) }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:app) { Web::Api::Projects.new }
  let(:operation) { Minitest::Mock.new }

  before do
    Web::Api::Projects.set :operation, operation
  end

  after do
    Web::Api::Sections.set :operation, Paleolog::Operation::Section
    Paleolog::Repo::User.delete_all
  end

  describe 'GET /api/sections' do
    it 'rejects guest access' do
      assert_unauthorized(-> { get '/api/sections', {} })
    end

    it 'accepts logged in user' do
      operation.expect :find_all_for_user, [], [user.id]
      login(user)
      assert_permitted(-> { get '/api/sections', {} })
    end

    describe 'with user' do
      before do
        login(user)
      end

      it 'returns empty collection' do
        operation.expect :find_all_for_user, [], [user.id]

        get '/api/sections'
        assert_predicate last_response, :ok?, "Expected 200, but got #{last_response.status}"
        response_body = JSON.parse(last_response.body)
        assert_empty response_body['sections']
      end

      it 'returns many sections' do
        other_section = Paleolog::Section.new(id: 2, name: 'section1', project: project)
        operation.expect :find_all_for_user, [section, other_section], [user.id]

        get '/api/sections'
        result = JSON.parse(last_response.body)['sections']
        assert_equal 2, result.size
        assert_equal([section.id, other_section.id], result.map { |r| r['id'] })
      end

      it 'returns all necessary attributes' do
        operation.expect :find_all_for_user, [section], [user.id]
        get '/api/sections'
        result = JSON.parse(last_response.body)['sections']

        assert_equal 1, result.size
        result = result.first
        assert_equal section.id, result['id']
        assert_equal section.name, result['name']
        assert_equal section.project_id, result['project_id']
        assert_equal section.created_at.to_s, result['created_at']
      end
    end
  end

  describe 'POST /api/sections' do
    it 'rejects guest access' do
      assert_unauthorized(-> { post '/api/sections', {} })
    end

    it 'rejects user observing the project' do
      Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: false))
      login(user)
      assert_forbidden(-> { post '/api/sections/1', {} })
    end


    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: true))
        login(user)
      end

      it 'creates section and returns its attributes' do
        params = { name: 'some name', project_id: project.id }
        operation.expect :create, [project, {}], **{ name: 'some name', project_id: project.id }
        post '/api/sections', params

        result = JSON.parse(last_response.body)['section']

        assert_equal section.id, result['id']
        assert_equal section.name, result['name']
        assert_equal section.project_id, result['project_id']
        assert_equal section.created_at.to_s, result['created_at']
      end

      it 'returns errors in case of failure' do
        params = { name: 'some name' }
        operation.expect :create, [nil, { project_id: 'missing' }], **{ name: 'some name' }
        post '/api/sections', params

        result = JSON.parse(last_response.body)
        assert result.key?('errors')

        assert_equal 'missing', result['errors']['project_id']
      end
    end
  end

  describe 'PATCH /api/sections/:id' do
    it 'rejects guest access' do
      assert_unauthorized(-> { patch '/api/sections/1', {} })
    end

    it 'rejects user observing the project' do
      Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: false))
      login(user)
      assert_forbidden(-> { patch '/api/sections/1', {} })
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: true))
        login(user)
      end

      it 'updates section name and returns its attributes' do
        params = { name: 'some other name' }
        operation.expect :rename, [section, {}], ['1'], name: 'some other name'
        patch '/api/sections/1', params

        result = JSON.parse(last_response.body)['section']

        assert_equal 1, result['id']
        assert_equal section.name, result['name']
        assert_equal section.created_at.to_s, result['created_at']
      end

      it 'returns errors in case of failure' do
        params = {}
        operation.expect :rename, [nil, { name: 'missing' }], ['1'], name: nil
        patch '/api/sections/1', params

        result = JSON.parse(last_response.body)
        assert result.key?('errors')

        assert_equal 'missing', result['errors']['name']
      end
    end
  end
end
