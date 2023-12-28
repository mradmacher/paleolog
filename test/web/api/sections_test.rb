# frozen_string_literal: true

require 'web_helper'

describe 'Sections' do
  include Rack::Test::Methods

  let(:app) { Web::Api::Sections.new }
  let(:repo) { Paleolog::Repo }
  let(:user) do
    repo.find(
      Paleolog::User,
      repo.save(Paleolog::User.new(login: 'test', password: 'test123')),
    )
  end
  let(:project) do
    happy_operation_for(Paleolog::Operation::Project, user)
      .create(name: 'project for section')
      .value
  end
  let(:researcher) do
    Paleolog::Repo::Researcher.find_for_project_and_user(project.id, user.id)
  end

  after do
    repo.for(Paleolog::Researcher).delete_all
    repo.for(Paleolog::User).delete_all
    repo.for(Paleolog::Sample).delete_all
    repo.for(Paleolog::Section).delete_all
    repo.for(Paleolog::Project).delete_all
  end

  describe 'GET /api/sections/:id' do
    let(:section) do
      happy_operation_for(Paleolog::Operation::Section, user).create(
        name: 'some project', project_id: project.id,
      ).value
    end

    before do
      refute_nil section
    end

    it 'rejects guest access' do
      assert_unauthorized(-> { get "/api/sections/#{section.id}" })
    end

    it 'rejects user not being a researcher in the project' do
      repo.for(Paleolog::Researcher).delete(researcher.id)
      login(user)
      assert_forbidden(-> { get "/api/sections/#{section.id}" })
    end

    describe 'with authorized user' do
      before do
        login(user)
      end

      it 'returns error if section does not exist' do
        get "/api/sections/#{section.id + 1}"
        assert_equal 403, last_response.status
      end

      it 'returns section attributes' do
        get "/api/sections/#{section.id}"
        assert_equal 200, last_response.status
        result = JSON.parse(last_response.body)['section']
        assert_equal section.id, result['id']
        assert_equal section.name, result['name']
        assert_equal section.project_id, result['project_id']
      end

      it 'returns section samples' do
        result = happy_operation_for(Paleolog::Operation::Sample, user).create(
          section_id: section.id,
          name: 'sample 1 for section',
          description: 'sample 1 description',
          weight: 1.0,
        )
        assert_predicate result, :success?
        sample1 = result.value

        result = happy_operation_for(Paleolog::Operation::Sample, user).create(
          section_id: section.id,
          name: 'sample 2 for section',
          description: 'sample 2 description',
        )
        assert_predicate result, :success?
        sample2 = result.value

        get "/api/sections/#{section.id}"
        assert_equal 200, last_response.status
        result = JSON.parse(last_response.body)['section']
        samples = result['samples']
        assert samples.is_a?(Array)

        found_sample = samples.detect { |s| s['id'] == sample1.id }
        refute_nil found_sample
        assert_equal sample1.id, found_sample['id']
        assert_equal section.id, found_sample['section_id']
        assert_equal sample1.name, found_sample['name']
        assert_equal sample1.description, found_sample['description']
        assert_equal '1.00', found_sample['weight']

        found_sample = samples.detect { |s| s['id'] == sample2.id }
        refute_nil found_sample
        assert_equal sample2.id, found_sample['id']
        assert_equal section.id, found_sample['section_id']
        assert_equal sample2.name, found_sample['name']
        assert_equal sample2.description, found_sample['description']
        assert_nil found_sample['weight']
      end
    end
  end

  describe 'POST /api/sections' do
    it 'rejects guest access' do
      assert_unauthorized(-> { post '/api/sections', { project_id: project.id } })
    end

    it 'rejects user observing the project' do
      repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))
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
      repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))
      login(user)
      assert_forbidden(-> { patch '/api/sections/1', { name: 'some new name', project_id: project.id } })
    end

    describe 'with user' do
      let(:section) do
        happy_operation_for(Paleolog::Operation::Section, user).create(
          name: 'some project', project_id: project.id,
        ).value
      end

      before do
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
