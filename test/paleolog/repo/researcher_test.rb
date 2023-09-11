# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Researcher do
  let(:repo) { Paleolog::Repo::Researcher }
  let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Project')) }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'User', password: 'passwd123')) }

  after do
    repo.delete_all
  end

  def assign_observer_role(user, project)
    Paleolog::Repo.save(Paleolog::Researcher.new(user: user, project: project))
  end

  def assign_manager_role(user, project)
    Paleolog::Repo.save(Paleolog::Researcher.new(user: user, project: project, manager: true))
  end

  describe '#project_role' do
    it 'returns empty result when user does not participate in project' do
      result = repo.project_role(project.id, user.id)
      assert_equal Paleolog::Repo::Researcher::NONE, result
    end

    it 'returns observer when user participates in project as observer' do
      assign_observer_role(user, project)
      result = repo.project_role(project.id, user.id)
      assert_equal Paleolog::Repo::Researcher::OBSERVER, result
    end

    it 'returns manager when user participates in project as manager' do
      assign_manager_role(user, project)
      result = repo.project_role(project.id, user.id)
      assert_equal Paleolog::Repo::Researcher::MANAGER, result
    end
  end

  describe '#section_role' do
    let(:section) do
      result = Paleolog::Operation::Section.new(
        Paleolog::Repo, HappyAuthorizer.new,
      ).create(
        { name: 'Some Name', project_id: project.id },
      )
      assert_predicate result, :success?
      result.value
    end

    it 'returns empty result when user does not participate in project' do
      result = repo.section_role(section.id, user.id)
      assert_equal Paleolog::Repo::Researcher::NONE, result
    end

    it 'returns observer when user participates in project as observer' do
      assign_observer_role(user, project)
      result = repo.section_role(section.id, user.id)
      assert_equal Paleolog::Repo::Researcher::OBSERVER, result
    end

    it 'returns manager when user participates in project as manager' do
      assign_manager_role(user, project)
      result = repo.section_role(section.id, user.id)
      assert_equal Paleolog::Repo::Researcher::MANAGER, result
    end
  end

  describe '#sample_role' do
    let(:section) do
      result = Paleolog::Operation::Section.new(
        Paleolog::Repo, HappyAuthorizer.new,
      ).create(
        { name: 'Some Name', project_id: project.id },
      )
      assert_predicate result, :success?
      result.value
    end

    let(:sample) do
      result = Paleolog::Operation::Sample.new(
        Paleolog::Repo, HappyAuthorizer.new,
      ).create(
        { name: 'Some Name', section_id: section.id },
      )
      assert_predicate result, :success?
      result.value
    end

    it 'returns empty result when user does not participate in project' do
      result = repo.sample_role(sample.id, user.id)
      assert_equal Paleolog::Repo::Researcher::NONE, result
    end

    it 'returns observer when user participates in project as observer' do
      assign_observer_role(user, project)
      result = repo.sample_role(sample.id, user.id)
      assert_equal Paleolog::Repo::Researcher::OBSERVER, result
    end

    it 'returns manager when user participates in project as manager' do
      assign_manager_role(user, project)
      result = repo.sample_role(sample.id, user.id)
      assert_equal Paleolog::Repo::Researcher::MANAGER, result
    end
  end

  describe '#counting_role' do
    let(:counting) do
      result = Paleolog::Operation::Counting.new(
        Paleolog::Repo, HappyAuthorizer.new,
      ).create(
        { name: 'Some Name', project_id: project.id },
      )
      assert_predicate result, :success?
      result.value
    end

    it 'returns empty result when user does not participate in project' do
      result = repo.counting_role(counting.id, user.id)
      assert_equal Paleolog::Repo::Researcher::NONE, result
    end

    it 'returns observer when user participates in project as observer' do
      assign_observer_role(user, project)
      result = repo.counting_role(counting.id, user.id)
      assert_equal Paleolog::Repo::Researcher::OBSERVER, result
    end

    it 'returns manager when user participates in project as manager' do
      assign_manager_role(user, project)
      result = repo.counting_role(counting.id, user.id)
      assert_equal Paleolog::Repo::Researcher::MANAGER, result
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
