# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::ResearchParticipation do
  let(:repo) { Paleolog::Repo::ResearchParticipation.new }

  after do
    repo.delete_all
  end

  describe '#all_for_project' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Project')) }
    let(:other_project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Project')) }
    let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'User', password: 'passwd123')) }
    let(:other_user) { Paleolog::Repo.save(Paleolog::User.new(login: 'Other User', password: 'passwd123')) }

    it 'returns all participations for a project' do
      participation1 = Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project))
      participation2 = Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: other_user, project: project))
      Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: other_project))

      result = repo.all_for_project(project.id)
      assert_equal([participation1.id, participation2.id], result.map(&:id))
    end
  end
end
