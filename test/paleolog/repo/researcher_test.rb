# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Researcher do
  let(:repo) { Paleolog::Repo::Researcher }
  let(:project_id) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Project')) }
  let(:user) do
    Paleolog::Repo.find(
      Paleolog::User,
      Paleolog::Repo.save(Paleolog::User.new(login: 'User', password: 'passwd123')),
    )
  end
  let(:user_id) { user.id }

  after do
    repo.delete_all
    Paleolog::Repo.delete_all(Paleolog::User)
    Paleolog::Repo.delete_all(Paleolog::Sample)
    Paleolog::Repo.delete_all(Paleolog::Section)
    Paleolog::Repo.delete_all(Paleolog::Counting)
    Paleolog::Repo.delete_all(Paleolog::Project)
  end

  def assign_observer_role(user_id, project_id)
    Paleolog::Repo.save(Paleolog::Researcher.new(user_id: user_id, project_id: project_id))
  end

  def assign_manager_role(user_id, project_id)
    Paleolog::Repo.save(Paleolog::Researcher.new(user_id: user_id, project_id: project_id, manager: true))
  end

  describe '#project_role' do
    it 'returns empty result when user does not participate in project' do
      result = repo.project_role(project_id, user_id)
      assert_equal Paleolog::Repo::Researcher::NONE, result
    end

    it 'returns observer when user participates in project as observer' do
      assign_observer_role(user_id, project_id)
      result = repo.project_role(project_id, user_id)
      assert_equal Paleolog::Repo::Researcher::OBSERVER, result
    end

    it 'returns manager when user participates in project as manager' do
      assign_manager_role(user_id, project_id)
      result = repo.project_role(project_id, user_id)
      assert_equal Paleolog::Repo::Researcher::MANAGER, result
    end
  end

  describe '#section_role' do
    let(:section_id) do
      Paleolog::Repo.save(Paleolog::Section.new(name: 'Some Name', project_id: project_id))
    end

    it 'returns empty result when user does not participate in project' do
      result = repo.section_role(section_id, user_id)
      assert_equal Paleolog::Repo::Researcher::NONE, result
    end

    it 'returns observer when user participates in project as observer' do
      assign_observer_role(user_id, project_id)
      result = repo.section_role(section_id, user_id)
      assert_equal Paleolog::Repo::Researcher::OBSERVER, result
    end

    it 'returns manager when user participates in project as manager' do
      assign_manager_role(user_id, project_id)
      result = repo.section_role(section_id, user_id)
      assert_equal Paleolog::Repo::Researcher::MANAGER, result
    end
  end

  describe '#sample_role' do
    let(:section_id) do
      Paleolog::Repo.save(Paleolog::Section.new(name: 'Some Name', project_id: project_id))
    end
    let(:sample_id) do
      Paleolog::Repo.save(Paleolog::Sample.new(name: 'Some Name', section_id: section_id))
    end

    it 'returns empty result when user does not participate in project' do
      result = repo.sample_role(sample_id, user_id)
      assert_equal Paleolog::Repo::Researcher::NONE, result
    end

    it 'returns observer when user participates in project as observer' do
      assign_observer_role(user_id, project_id)
      result = repo.sample_role(sample_id, user_id)
      assert_equal Paleolog::Repo::Researcher::OBSERVER, result
    end

    it 'returns manager when user participates in project as manager' do
      assign_manager_role(user_id, project_id)
      result = repo.sample_role(sample_id, user_id)
      assert_equal Paleolog::Repo::Researcher::MANAGER, result
    end
  end

  describe '#counting_role' do
    let(:counting_id) do
      Paleolog::Repo.save(Paleolog::Counting.new(name: 'Some Name', project_id: project_id))
    end

    it 'returns empty result when user does not participate in project' do
      result = repo.counting_role(counting_id, user_id)
      assert_equal Paleolog::Repo::Researcher::NONE, result
    end

    it 'returns observer when user participates in project as observer' do
      assign_observer_role(user_id, project_id)
      result = repo.counting_role(counting_id, user_id)
      assert_equal Paleolog::Repo::Researcher::OBSERVER, result
    end

    it 'returns manager when user participates in project as manager' do
      assign_manager_role(user_id, project_id)
      result = repo.counting_role(counting_id, user_id)
      assert_equal Paleolog::Repo::Researcher::MANAGER, result
    end
  end

  describe '#all_for_project' do
    let(:other_project_id) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Other Project')) }
    let(:other_user_id) { Paleolog::Repo.save(Paleolog::User.new(login: 'Other User', password: 'passwd123')) }

    it 'returns all researches for a project' do
      researcher1_id = Paleolog::Repo.save(Paleolog::Researcher.new(user_id: user_id, project_id: project_id))
      researcher2_id = Paleolog::Repo.save(Paleolog::Researcher.new(user_id: other_user_id, project_id: project_id))
      Paleolog::Repo.save(Paleolog::Researcher.new(user_id: user_id, project_id: other_project_id))

      result = repo.all_for_project(project_id)
      assert_equal([researcher1_id, researcher2_id], result.map(&:id))
    end
  end
end
