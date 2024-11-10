# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Authorizer do
  let(:session) { {} }
  let(:authorizer) { Paleolog::Authorizer.new(session) }
  let(:user) do
    Paleolog::Repo.find(
      Paleolog::User,
      Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')),
    )
  end
  let(:other_user) do
    Paleolog::Repo.find(
      Paleolog::User,
      Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123')),
    )
  end

  after do
    Paleolog::Repo.delete_all(Paleolog::Occurrence)
    Paleolog::Repo.delete_all(Paleolog::Species)
    Paleolog::Repo.delete_all(Paleolog::Group)
    Paleolog::Repo.delete_all(Paleolog::Sample)
    Paleolog::Repo.delete_all(Paleolog::Section)
    Paleolog::Repo.delete_all(Paleolog::Counting)
    Paleolog::Repo.delete_all(Paleolog::User)
    Paleolog::Repo.delete_all(Paleolog::Researcher)
    Paleolog::Repo.delete_all(Paleolog::Project)
  end

  describe '#can_manage?(Project)' do
    let(:project) do
      happy_operation_for(Paleolog::Operation::Project, user)
        .create(name: 'Just a Project').value
    end
    let(:researcher) { Paleolog::Repo::Researcher.find_for_project_and_user(project.id, user.id) }

    it 'is false for not authenticated' do
      refute authorizer.can_manage?(Paleolog::Project, project.id)
    end

    it 'is false for guest' do
      authorizer.login(other_user)

      refute authorizer.can_manage?(Paleolog::Project, project.id)
    end

    it 'is false for observer' do
      authorizer.login(user)
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))

      refute authorizer.can_manage?(Paleolog::Project, project.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))

      assert authorizer.can_manage?(Paleolog::Project, project.id)
    end
  end

  describe '#can_manage?(Section)' do
    let(:project) do
      happy_operation_for(Paleolog::Operation::Project, user)
        .create(name: 'Just a Project').value
    end
    let(:researcher) { Paleolog::Repo::Researcher.find_for_project_and_user(project.id, user.id) }
    let(:section) do
      happy_operation_for(Paleolog::Operation::Section, user)
        .create(name: 'Section XYZ', project_id: project.id).value
    end

    it 'is false for guest' do
      authorizer.login(other_user)

      refute authorizer.can_manage?(Paleolog::Section, section.id)
    end

    it 'is false for observer' do
      authorizer.login(user)
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))

      refute authorizer.can_manage?(Paleolog::Section, section.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))

      assert authorizer.can_manage?(Paleolog::Section, section.id)
    end
  end

  describe '#can_view?(Section)' do
    let(:project) do
      happy_operation_for(Paleolog::Operation::Project, user)
        .create(name: 'Just a Project').value
    end
    let(:researcher) { Paleolog::Repo::Researcher.find_for_project_and_user(project.id, user.id) }
    let(:section) do
      happy_operation_for(Paleolog::Operation::Section, user)
        .create(name: 'Section XYZ', project_id: project.id).value
    end

    it 'is false for guest' do
      authorizer.login(other_user)

      refute authorizer.can_view?(Paleolog::Section, section.id)
    end

    it 'is true for observer' do
      authorizer.login(user)
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))

      assert authorizer.can_view?(Paleolog::Section, section.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))

      assert authorizer.can_view?(Paleolog::Section, section.id)
    end
  end

  describe '#can_manage?(Counting)' do
    let(:project) do
      happy_operation_for(Paleolog::Operation::Project, user)
        .create(name: 'Just a Project').value
    end
    let(:researcher) { Paleolog::Repo::Researcher.find_for_project_and_user(project.id, user.id) }
    let(:counting) do
      happy_operation_for(Paleolog::Operation::Counting, user)
        .create(name: 'Counting XYZ', project_id: project.id).value
    end

    it 'is false for not authenticated' do
      refute authorizer.can_manage?(Paleolog::Counting, counting.id)
    end

    it 'is false for guest' do
      authorizer.login(other_user)

      refute authorizer.can_manage?(Paleolog::Counting, counting.id)
    end

    it 'is false for observer' do
      authorizer.login(user)
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))

      refute authorizer.can_manage?(Paleolog::Counting, counting.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))

      assert authorizer.can_manage?(Paleolog::Counting, counting.id)
    end
  end

  describe '#can_view?(Counting)' do
    let(:project) do
      happy_operation_for(Paleolog::Operation::Project, user)
        .create(name: 'Just a Project').value
    end
    let(:researcher) { Paleolog::Repo::Researcher.find_for_project_and_user(project.id, user.id) }
    let(:counting) do
      happy_operation_for(Paleolog::Operation::Counting, user)
        .create(name: 'Counting XYZ', project_id: project.id).value
    end

    it 'is false for not authenticated' do
      refute authorizer.can_view?(Paleolog::Counting, counting.id)
    end

    it 'is false for guest' do
      authorizer.login(other_user)

      refute authorizer.can_view?(Paleolog::Counting, counting.id)
    end

    it 'is true for observer' do
      authorizer.login(user)
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: false))

      assert authorizer.can_view?(Paleolog::Counting, counting.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      Paleolog::Repo.save(Paleolog::Researcher.new(id: researcher.id, manager: true))

      assert authorizer.can_view?(Paleolog::Counting, counting.id)
    end
  end
end
