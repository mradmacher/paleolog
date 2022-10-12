# frozen_string_literal: true

require 'web_helper'

describe 'Occurrences' do
  include Rack::Test::Methods

  let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'some project')) }
  let(:counting) { Paleolog::Repo.save(Paleolog::Counting.new(name: 'some counting', project: project)) }
  let(:section) { Paleolog::Repo.save(Paleolog::Section.new(name: 'some section', project: project)) }
  let(:sample) { Paleolog::Repo.save(Paleolog::Sample.new(name: 'some sample', section: section)) }

  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:session) { {} }

  # rubocop:disable Metrics/AbcSize
  def assert_requires_observer(action, project)
    user = Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123'))

    action.call
    assert last_response.redirect?, 'Expected redirect when no user'

    session = {}
    Paleolog::Authorizer.new(session).login('test', 'test123')
    env 'rack.session', session
    action.call
    assert last_response.redirect?, 'Expected redirect when user not in project'

    participation = Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project))
    action.call
    assert last_response.ok?

    Paleolog::Repo::ResearchParticipation.update(participation.id, manager: true)
    action.call
    assert last_response.ok?
  end
  # rubocop:enable Metrics/AbcSize

  after do
    Paleolog::Repo::User.delete_all
  end

  describe 'GET /projects/project_id/occurrences' do
    it 'requires user participating in the project as observer' do
      assert_requires_observer(
        lambda {
          get "/projects/#{project.id}/occurrences?counting=#{counting.id}&section=#{section.id}&sample=#{sample.id}"
        },
        project,
      )
    end

    describe 'with user' do
      before do
        Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project, manager: false))
        Paleolog::Authorizer.new(session).login('test', 'test123')
        env 'rack.session', session
      end

      it 'redirects to some sections, sample and counting' do
        get "/projects/#{project.id}/occurrences"
        assert last_response.redirect?, "Expected 302 but got #{last_response.status}"
      end

      it 'returns 200 if counting, sectiona and sample provided' do
        get "/projects/#{project.id}/occurrences?counting=#{counting.id}&section=#{section.id}&sample=#{sample.id}"
        assert last_response.ok?, "Expected 200, but got #{last_response.status}"
      end
    end
  end
end
