# frozen_string_literal: true

require 'web_helper'

describe 'Occurrences' do
  include Rack::Test::Methods

  let(:user) do
    Paleolog::Repo.find(
      Paleolog::User,
      Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')),
    )
  end
  let(:project) do
    happy_operation_for(Paleolog::Operation::Project, user)
      .create(name: 'some project').value
  end
  let(:counting) do
    happy_operation_for(Paleolog::Operation::Counting, user)
      .create(name: 'some counting', project_id: project.id).value
  end
  let(:section) do
    happy_operation_for(Paleolog::Operation::Section, user)
      .create(name: 'some section', project_id: project.id).value
  end
  let(:sample) do
    happy_operation_for(Paleolog::Operation::Sample, user)
      .create(name: 'some sample', section_id: section.id).value
  end
  let(:researcher) do
    Paleolog::Repo::Researcher.find_for_project_and_user(project.id, user.id)
  end

  def assert_requires_observer(action)
    action.call
    assert_predicate last_response, :redirect?, 'Expected redirect when no user'

    other_user = Paleolog::Repo.find(
      Paleolog::User,
      Paleolog::Repo.save(Paleolog::User.new(login: 'other test', password: 'test123')),
    )
    login(other_user)
    action.call
    assert_predicate last_response, :redirect?, 'Expected redirect when user not in project'

    login(user)
    action.call
    assert_predicate last_response, :ok?
  end

  after do
    Paleolog::Repo::Researcher.delete_all
    Paleolog::Repo::User.delete_all
    Paleolog::Repo::Project.delete_all
    Paleolog::Repo::Counting.delete_all
    Paleolog::Repo::Sample.delete_all
    Paleolog::Repo::Section.delete_all
  end

  describe 'GET /projects/:project_id/countings/:id' do
    it 'requires user participating in the project as observer' do
      assert_requires_observer(
        lambda {
          get "/projects/#{project.id}/countings/#{counting.id}"
        },
        project,
      )
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))
        login(user)
      end

      it 'returns 200' do
        get "/projects/#{project.id}/countings/#{counting.id}"
        assert_predicate last_response, :ok?, "Expected 200, but got #{last_response.status}"
      end
    end
  end
end
