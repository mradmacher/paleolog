# frozen_string_literal: true

require 'web_helper'

describe 'Occurrences' do
  include Rack::Test::Methods

  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end
  let(:project) do
    happy_operation_for(Paleolog::Repository::Project, user)
      .create(name: 'some project').value
  end
  let(:counting) do
    happy_operation_for(Paleolog::Repository::Counting, user)
      .create(name: 'some counting', project_id: project.id).value
  end
  let(:section) do
    happy_operation_for(Paleolog::Repository::Section, user)
      .create(name: 'some section', project_id: project.id).value
  end
  let(:sample) do
    happy_operation_for(Paleolog::Repository::Sample, user)
      .create(name: 'some sample', section_id: section.id).value
  end

  def assert_requires_observer(action)
    action.call

    assert_predicate last_response, :redirect?, 'Expected redirect when no user'

    other_user = Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'other test', password: 'test123').value
    login(other_user)
    action.call

    assert_predicate last_response, :redirect?, 'Expected redirect when user not in project'

    login(user)
    action.call

    assert_predicate last_response, :ok?
  end

  describe 'GET /projects/:project_id/countings/:id' do
    it 'requires user participating in the project as observer' do
      assert_requires_observer(
        lambda {
          get "/projects/#{project.id}/countings/#{counting.id}"
        },
      )
    end

    describe 'with user' do
      before do
        happy_operation_for(Paleolog::Repository::Project, user)
          .update_researcher(project_id: project.id, user_id: user.id, manager: false)
        login(user)
      end

      it 'returns 200' do
        get "/projects/#{project.id}/countings/#{counting.id}"

        assert_predicate last_response, :ok?, "Expected 200, but got #{last_response.status}"
      end
    end
  end
end
