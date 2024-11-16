# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Authorizer do
  let(:session) { {} }
  let(:authorizer) { Paleolog::Authorizer.new(session) }
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end
  let(:other_user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'other user', password: 'test123').value
  end

  describe '#can_view?(Species)' do
    let(:group) do
      happy_operation_for(Paleolog::Repository::Group, user).create(name: 'A Group').value
    end
    let(:species) do
      happy_operation_for(Paleolog::Repository::Species, user)
        .create(name: 'Just a Test', group_id: group.id).value
    end

    it 'is false for not authenticated' do
      refute authorizer.can_view?(Paleolog::Species, species.id)
    end

    it 'is true for logged user' do
      authorizer.login(user)

      assert authorizer.can_view?(Paleolog::Species, species.id)
    end
  end

  describe '#can_manage?(Project)' do
    let(:project) do
      happy_operation_for(Paleolog::Repository::Project, user)
        .create(name: 'Just a Project').value
    end

    it 'is false for not authenticated' do
      refute authorizer.can_manage?(Paleolog::Project, project.id)
    end

    it 'is false for guest' do
      authorizer.login(other_user)

      refute authorizer.can_manage?(Paleolog::Project, project.id)
    end

    it 'is false for observer' do
      authorizer.login(user)
      happy_operation_for(Paleolog::Repository::Project, user)
        .update_researcher(project_id: project.id, user_id: user.id, manager: false)

      refute authorizer.can_manage?(Paleolog::Project, project.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      happy_operation_for(Paleolog::Repository::Project, user)
        .update_researcher(project_id: project.id, user_id: user.id, manager: true)

      assert authorizer.can_manage?(Paleolog::Project, project.id)
    end
  end

  describe '#can_manage?(Section)' do
    let(:project) do
      happy_operation_for(Paleolog::Repository::Project, user)
        .create(name: 'Just a Project').value
    end
    let(:section) do
      happy_operation_for(Paleolog::Repository::Section, user)
        .create(name: 'Section XYZ', project_id: project.id).value
    end

    it 'is false for guest' do
      authorizer.login(other_user)

      refute authorizer.can_manage?(Paleolog::Section, section.id)
    end

    it 'is false for observer' do
      authorizer.login(user)
      happy_operation_for(Paleolog::Repository::Project, user)
        .update_researcher(project_id: project.id, user_id: user.id, manager: false)

      refute authorizer.can_manage?(Paleolog::Section, section.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      happy_operation_for(Paleolog::Repository::Project, user)
        .update_researcher(project_id: project.id, user_id: user.id, manager: true)

      assert authorizer.can_manage?(Paleolog::Section, section.id)
    end
  end

  describe '#can_view?(Section)' do
    let(:project) do
      happy_operation_for(Paleolog::Repository::Project, user)
        .create(name: 'Just a Project').value
    end
    let(:section) do
      happy_operation_for(Paleolog::Repository::Section, user)
        .create(name: 'Section XYZ', project_id: project.id).value
    end

    it 'is false for guest' do
      authorizer.login(other_user)

      refute authorizer.can_view?(Paleolog::Section, section.id)
    end

    it 'is true for observer' do
      authorizer.login(user)
      happy_operation_for(Paleolog::Repository::Project, user)
        .update_researcher(project_id: project.id, user_id: user.id, manager: false)

      assert authorizer.can_view?(Paleolog::Section, section.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      happy_operation_for(Paleolog::Repository::Project, user)
        .update_researcher(project_id: project.id, user_id: user.id, manager: true)

      assert authorizer.can_view?(Paleolog::Section, section.id)
    end
  end

  describe '#can_manage?(Counting)' do
    let(:project) do
      happy_operation_for(Paleolog::Repository::Project, user)
        .create(name: 'Just a Project').value
    end
    let(:counting) do
      happy_operation_for(Paleolog::Repository::Counting, user)
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
      happy_operation_for(Paleolog::Repository::Project, user)
        .update_researcher(project_id: project.id, user_id: user.id, manager: false)
      authorizer.login(user)

      refute authorizer.can_manage?(Paleolog::Counting, counting.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      happy_operation_for(Paleolog::Repository::Project, user)
        .update_researcher(project_id: project.id, user_id: user.id, manager: true)

      assert authorizer.can_manage?(Paleolog::Counting, counting.id)
    end
  end

  describe '#can_view?(Counting)' do
    let(:project) do
      happy_operation_for(Paleolog::Repository::Project, user)
        .create(name: 'Just a Project').value
    end
    let(:counting) do
      happy_operation_for(Paleolog::Repository::Counting, user)
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
      happy_operation_for(Paleolog::Repository::Project, user)
        .update_researcher(project_id: project.id, user_id: user.id, manager: false)

      assert authorizer.can_view?(Paleolog::Counting, counting.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      happy_operation_for(Paleolog::Repository::Project, user)
        .update_researcher(project_id: project.id, user_id: user.id, manager: true)

      assert authorizer.can_view?(Paleolog::Counting, counting.id)
    end
  end
end
