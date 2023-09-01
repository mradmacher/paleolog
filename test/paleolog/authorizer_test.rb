# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Authorizer do
  let(:session) { {} }
  let(:authorizer) { Paleolog::Authorizer.new(session) }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }

  describe '#can_manage?(Project)' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Project for Counting')) }
    let(:researcher) { Paleolog::Repo.save(Paleolog::Researcher.new(user_id: user.id, project_id: project.id)) }

    it 'is false for not authenticated' do
      refute authorizer.can_manage?(Paleolog::Project, project.id)
    end

    it 'is false for guest' do
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123'))
      authorizer.login(other_user)
      refute authorizer.can_manage?(Paleolog::Project, project.id)
    end

    it 'is false for observer' do
      authorizer.login(user)
      Paleolog::Repo::Researcher.update(researcher.id, manager: false)
      refute authorizer.can_manage?(Paleolog::Project, project.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      Paleolog::Repo::Researcher.update(researcher.id, manager: true)
      assert authorizer.can_manage?(Paleolog::Project, project.id)
    end
  end

  describe '#can_manage?(Section)' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Project for Counting')) }
    let(:researcher) { Paleolog::Repo.save(Paleolog::Researcher.new(user_id: user.id, project_id: project.id)) }
    let(:section) { Paleolog::Repo.save(Paleolog::Section.new(name: 'Section XYZ', project_id: project.id)) }

    it 'is false for guest' do
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123'))
      authorizer.login(other_user)
      refute authorizer.can_manage?(Paleolog::Section, section.id)
    end

    it 'is false for observer' do
      authorizer.login(user)
      Paleolog::Repo::Researcher.update(researcher.id, manager: false)
      refute authorizer.can_manage?(Paleolog::Section, section.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      Paleolog::Repo::Researcher.update(researcher.id, manager: true)
      assert authorizer.can_manage?(Paleolog::Section, section.id)
    end
  end

  describe '#can_manage?(Counting)' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Project for Counting')) }
    let(:researcher) { Paleolog::Repo.save(Paleolog::Researcher.new(user_id: user.id, project_id: project.id)) }
    let(:counting) { Paleolog::Repo.save(Paleolog::Counting.new(name: 'Counting XYZ', project_id: project.id)) }

    it 'is false for not authenticated' do
      refute authorizer.can_manage?(Paleolog::Counting, counting.id)
    end

    it 'is false for guest' do
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123'))
      authorizer.login(other_user)
      refute authorizer.can_manage?(Paleolog::Counting, counting.id)
    end

    it 'is false for observer' do
      authorizer.login(user)
      Paleolog::Repo::Researcher.update(researcher.id, manager: false)
      refute authorizer.can_manage?(Paleolog::Counting, counting.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      Paleolog::Repo::Researcher.update(researcher.id, manager: true)
      assert authorizer.can_manage?(Paleolog::Counting, counting.id)
    end
  end

  describe '#can_view?(Counting)' do
    let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'Project for Counting')) }
    let(:researcher) { Paleolog::Repo.save(Paleolog::Researcher.new(user_id: user.id, project_id: project.id)) }
    let(:counting) { Paleolog::Repo.save(Paleolog::Counting.new(name: 'Counting XYZ', project_id: project.id)) }

    it 'is false for not authenticated' do
      refute authorizer.can_view?(Paleolog::Counting, counting.id)
    end

    it 'is false for guest' do
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123'))
      authorizer.login(other_user)
      refute authorizer.can_view?(Paleolog::Counting, counting.id)
    end

    it 'is true for observer' do
      authorizer.login(user)
      Paleolog::Repo::Researcher.update(researcher.id, manager: false)
      assert authorizer.can_view?(Paleolog::Counting, counting.id)
    end

    it 'is true for manager' do
      authorizer.login(user)
      Paleolog::Repo::Researcher.update(researcher.id, manager: true)
      assert authorizer.can_view?(Paleolog::Counting, counting.id)
    end
  end
end
