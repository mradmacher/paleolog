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
      project_without_user = Paleolog::Repo.save(Paleolog::Project.new(name: 'project1'))
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other test', password: 'test123'))
      project_with_different_user = Paleolog::Repo.save(Paleolog::Project.new(name: 'project2'))
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
    it 'adds new project' do
      result = operation.create(name: 'Some Name', user_id: user.id)
      assert_predicate result, :success?
      refute_nil result.value.id
      assert_equal 'Some Name', result.value.name
    end

    it 'adds user as project manager' do
      result = operation.create(name: 'Some Name', user_id: user.id)
      assert_predicate result, :success?
      refute_nil result.value.id
      participations = Paleolog::Repo::ResearchParticipation.all_for_project(result.value.id)
      assert_equal 1, participations.size
      participation = participations.first
      assert_equal user.id, participation.user_id
      assert_predicate participation, :manager
    end

    it 'adds created_at timestamp' do
      result = operation.create(name: 'Some Name', user_id: user.id)
      assert_predicate result, :success?
      refute_nil result.value.created_at
    end

    it 'does not complain when name not taken yet' do
      result = operation.create(name: 'Some Name', user_id: user.id)
      assert_predicate result, :success?

      result = operation.create(name: 'Other Name', user_id: user.id)
      assert_predicate result, :success?
    end

    it 'complains when name is blank' do
      result = operation.create(name: nil, user_id: user.id)
      assert_predicate result, :failure?
      assert_equal :blank, result.error[:name]

      result = operation.create(name: '  ', user_id: user.id)
      assert_predicate result, :failure?
      assert_equal :blank, result.error[:name]
    end

    it 'complains when name already exists' do
      result = operation.create(name: 'Some Name', user_id: user.id)
      assert_predicate result, :success?

      result = operation.create(name: 'Some Name', user_id: user.id)
      assert_predicate result, :failure?
      assert_equal :taken, result.error[:name]
    end

    it 'complains when name is too long' do
      max = 255
      result = operation.create(name: 'a' * (max + 1), user_id: user.id)
      assert_predicate result, :failure?
      assert_equal :too_long, result.error[:name]

      result = operation.create(name: 'a' * max, user_id: user.id)
      assert_predicate result, :success?
    end

    it 'complains when name with different cases already exists' do
      result = operation.create(name: 'Some Name', user_id: user.id)
      assert_predicate result, :success?

      result = operation.create(name: ' some name ', user_id: user.id)
      assert_predicate result, :failure?
      assert_equal :taken, result.error[:name]
    end
  end
end
