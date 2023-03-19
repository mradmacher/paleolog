# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Project do
  let(:operation) { Paleolog::Operation::Project }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }

  after do
    Paleolog::Repo::Project.delete_all
  end

  describe '#find_all_for_user' do
    it 'returns empty collection when there are no projects' do
      result = operation.find_all_for_user(user.id)
      assert_empty result
    end

    it 'returns only projects user participates in' do
      project_with_different_user = Paleolog::Repo.save(Paleolog::Project.new(name: 'project1'))
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other test', password: 'test123'))
      Paleolog::Repo.save(Paleolog::Project.new(name: 'project2'))
      Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: other_user, project: project_with_different_user))
      project = Paleolog::Repo.save(Paleolog::Project.new(name: 'some project'))
      Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project))

      result = operation.find_all_for_user(user.id)
      assert_equal 1, result.size
      assert_equal project.id, result.first.id
    end

    it 'returns all necessary attributes' do
      project = Paleolog::Repo.save(Paleolog::Project.new(name: 'some project'))
      Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: user, project: project))
      result = operation.find_all_for_user(user.id)

      assert_equal 1, result.size
      assert_equal(project.id, result.first.id)
      assert_equal(project.name, result.first.name)
      assert_equal(project.created_at, result.first.created_at)
    end
  end

  describe '#create' do
    it 'rejects missing user' do
      _, errors = operation.create({ name: 'Some Name' }, user_id: nil)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
    end

    it 'adds new project' do
      project, errors = operation.create({ name: 'Some Name' }, user_id: user.id)
      assert_predicate errors, :empty?
      refute_nil project.id
      assert_equal 'Some Name', project.name
    end

    it 'adds user as project manager' do
      project, errors = operation.create({ name: 'Some Name' }, user_id: user.id)

      assert_predicate errors, :empty?
      refute_nil project.id
      participations = Paleolog::Repo::ResearchParticipation.all_for_project(project.id)
      assert_equal 1, participations.size
      participation = participations.first
      assert_equal user.id, participation.user_id
      assert_predicate participation, :manager
    end

    it 'adds created_at timestamp' do
      project, errors = operation.create({ name: 'Some Name' }, user_id: user.id)
      assert_predicate errors, :empty?
      refute_nil project.created_at
    end

    it 'complains when user missing' do
      project, errors = operation.create({ name: 'name' }, user_id: nil)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
      assert_nil project
    end

    it 'does not complain when name not taken yet' do
      project, errors = operation.create({ name: 'Some Name' }, user_id: user.id)
      assert_predicate errors, :empty?
      assert_equal 'Some Name', project.name

      project, errors = operation.create({ name: 'Other Name' }, user_id: user.id)
      assert_predicate errors, :empty?
      assert_equal 'Other Name', project.name
    end

    it 'complains when name is blank' do
      project, errors = operation.create({ name: nil }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]
      assert_nil project

      project, errors = operation.create({ name: '  ' }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]
      assert_nil project
    end

    it 'complains when name already exists' do
      project, errors = operation.create({ name: 'Some Name' }, user_id: user.id)
      assert_predicate errors, :empty?
      refute_nil project

      project, errors = operation.create({ name: 'Some Name' }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
      assert_nil project
    end

    it 'complains when name is too long' do
      max = 255
      project, errors = operation.create({ name: 'a' * (max + 1) }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :too_long, errors[:name]
      assert_nil project

      project, errors = operation.create({ name: 'a' * max }, user_id: user.id)
      assert_predicate errors, :empty?
      refute_nil project
    end

    it 'complains when name with different cases already exists' do
      _, errors = operation.create({ name: 'Some Name' }, user_id: user.id)
      assert_predicate errors, :empty?

      _, errors = operation.create({ name: ' some name ' }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
    end
  end

  describe '#rename' do
    let(:project_id) do
      project, errors = operation.create({ name: 'Some Name' }, user_id: user.id)
      assert_predicate errors, :empty?
      project.id
    end

    it 'rejects missing user' do
      _, errors = operation.rename({ id: project_id, name: 'Some Name' }, user_id: nil)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
    end

    it 'rejects guest access' do
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123'))
      _, errors = operation.rename({ id: project_id, name: 'Other Name' }, user_id: other_user.id)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
    end

    it 'rejects user observing the project' do
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123'))
      Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: other_user, project_id: project_id))

      _, errors = operation.rename({ id: project_id, name: 'Other Name' }, user_id: other_user.id)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
    end

    it 'renames project' do
      project, errors = operation.rename({ id: project_id, name: 'Other Name' }, user_id: user.id)
      assert_predicate errors, :empty?
      assert_equal 'Other Name', project.name
    end

    it 'can set the same name' do
      project, errors = operation.rename({ id: project_id, name: 'Some Name' }, user_id: user.id)
      assert_predicate errors, :empty?
      assert_equal 'Some Name', project.name
    end

    it 'complains when name is blank' do
      project, errors = operation.rename({ id: project_id, name: nil }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]
      assert_nil project

      project, errors = operation.rename({ id: project_id, name: '   ' }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]
      assert_nil project
    end

    it 'complains when name already exists' do
      _, errors = operation.create({ name: 'Other Name' }, user_id: user.id)
      assert_predicate errors, :empty?

      project, errors = operation.rename({ id: project_id, name: 'Other Name' }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
      assert_nil project
    end

    it 'complains when name is too long' do
      max = 255
      project, errors = operation.rename({ id: project_id, name: 'a' * (max + 1) }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :too_long, errors[:name]
      assert_nil project

      project, errors = operation.rename({ id: project_id, name: 'a' * max }, user_id: user.id)
      assert_predicate errors, :empty?
      assert_equal 'a' * max, project.name
    end

    it 'complains when name with different cases already exists' do
      _, errors = operation.create({ name: 'Other Name' }, user_id: user.id)
      assert_predicate errors, :empty?

      _, errors = operation.rename({ id: project_id, name: ' other name ' }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
    end
  end
end
