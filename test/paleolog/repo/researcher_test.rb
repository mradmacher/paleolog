# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Researcher do
  let(:repo) { Paleolog::Repo::Researcher }
  let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Project')) }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'User', password: 'passwd123')) }

  after do
    repo.delete_all
  end

  describe '#can_view_project?' do
    it 'is false when user does not participate in project' do
      refute repo.can_view_project?(user.id, project.id)
    end

    it 'is true when user participates in project as observer' do
      Paleolog::Repo.save(Paleolog::Researcher.new(user: user, project: project))
      assert repo.can_view_project?(user.id, project.id)
    end

    it 'is true when user participates in project as manager' do
      Paleolog::Repo.save(Paleolog::Researcher.new(user: user, project: project, manager: true))
      assert repo.can_view_project?(user.id, project.id)
    end
  end

  describe '#can_manage_project?' do
    it 'is false when user does not participate in project' do
      refute repo.can_manage_project?(user.id, project.id)
    end

    it 'is false when user participates in project as observer' do
      Paleolog::Repo.save(Paleolog::Researcher.new(user: user, project: project))
      refute repo.can_manage_project?(user.id, project.id)
    end

    it 'is true when user participates in project as manager' do
      Paleolog::Repo.save(Paleolog::Researcher.new(user: user, project: project, manager: true))
      assert repo.can_manage_project?(user.id, project.id)
    end
  end

  describe '#all_for_project' do
    let(:other_project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Project')) }
    let(:other_user) { Paleolog::Repo.save(Paleolog::User.new(login: 'Other User', password: 'passwd123')) }

    it 'returns all participations for a project' do
      participation1 = Paleolog::Repo.save(Paleolog::Researcher.new(user: user, project: project))
      participation2 = Paleolog::Repo.save(Paleolog::Researcher.new(user: other_user, project: project))
      Paleolog::Repo.save(Paleolog::Researcher.new(user: user, project: other_project))

      result = repo.all_for_project(project.id)
      assert_equal([participation1.id, participation2.id], result.map(&:id))
    end
  end
end
