# frozen_string_literal: true

require 'web_helper'

describe 'Sections' do
  include Rack::Test::Methods

  let(:app) { Web::Api::Sections.new }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:project) do
    project, errors = Paleolog::Operation::Project.create({ name: 'project for section' }, user_id: user.id)
    assert_predicate errors, :empty?
    project
  end
  let(:researcher) do
    Paleolog::Repo::Researcher.all_for_project(project.id).detect { |r| r.user_id == user.id }
  end

  after do
    Paleolog::Repo::Researcher.delete_all
    Paleolog::Repo::User.delete_all
    Paleolog::Repo::Section.delete_all
    Paleolog::Repo::Project.delete_all
  end

  describe 'POST /api/sections' do
    it 'rejects guest access' do
      assert_unauthorized(-> { post '/api/sections', { project_id: project.id } })
    end

    it 'rejects user observing the project' do
      Paleolog::Repo::ResearchParticipation.update(researcher.id, manager: false)
      login(user)
      assert_forbidden(-> { post '/api/sections', { project_id: project.id, name: 'some name' } })
    end

    describe 'with user' do
      before do
        login(user)
      end

      it 'creates section and returns its attributes' do
        params = { name: 'some name', project_id: project.id }
        post '/api/sections', params
        assert_equal 200, last_response.status

        result = JSON.parse(last_response.body)['section']

        refute_nil result['id']
        assert_equal 'some name', result['name']
        assert_equal project.id, result['project_id']
        refute_nil result['created_at']
      end

      it 'returns errors in case of failure' do
        params = { 'name' => '', project_id: project.id }
        post '/api/sections', params
        assert_equal 422, last_response.status

        result = JSON.parse(last_response.body)
        assert result.key?('errors')

        assert_equal 'blank', result['errors']['name']
      end
    end
  end

  describe 'PATCH /api/sections/:id' do
    it 'rejects guest access' do
      assert_unauthorized(-> { patch '/api/sections/1', { project_id: project.id } })
    end

    it 'rejects user observing the project' do
      Paleolog::Repo::ResearchParticipation.update(researcher.id, manager: false)
      login(user)
      assert_forbidden(-> { patch '/api/sections/1', { name: 'some new name', project_id: project.id } })
    end

    describe 'with user' do
      let(:section) do
        Paleolog::Operation::Section.create({ name: 'some project', project_id: project.id }, authorizer: HappyAuthorizer.new).first
      end

      before do
        refute_nil section
        login(user)
      end

      it 'updates section name and returns its attributes' do
        params = { 'name' => 'some other name' }
        patch "/api/sections/#{section.id}", params
        assert_equal 200, last_response.status

        result = JSON.parse(last_response.body)['section']

        assert_equal section.id, result['id']
        assert_equal 'some other name', result['name']
        assert_equal section.created_at.to_s, result['created_at']
      end

      it 'returns errors in case of failure' do
        patch "/api/sections/#{section.id}", {}

        assert_equal 422, last_response.status

        result = JSON.parse(last_response.body)
        assert result.key?('errors')

        assert_equal 'missing', result['errors']['name']
      end
    end
  end
end
