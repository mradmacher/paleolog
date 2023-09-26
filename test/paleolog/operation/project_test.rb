# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Project do
  let(:repo) { Paleolog::Repo }
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) { Paleolog::Operation::Project.new(repo, authorizer) }
  let(:happy_operation) { Paleolog::Operation::Project.new(repo, HappyAuthorizer.new) }
  let(:user) { repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }

  after do
    repo.for(Paleolog::Project).delete_all
    repo.for(Paleolog::Researcher).delete_all
    repo.for(Paleolog::User).delete_all
  end

  describe '#find_all_for_user' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.find_all_for_user(user.id)
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'returns empty collection when there are no projects' do
        result = operation.find_all_for_user(user.id)
        assert_predicate result, :success?
        assert_empty result.value
      end

      it 'returns only projects user participates in' do
        project_with_different_user = repo.save(Paleolog::Project.new(name: 'project1'))
        other_user = repo.save(Paleolog::User.new(login: 'other test', password: 'test123'))
        repo.save(Paleolog::Project.new(name: 'project2'))
        repo.save(Paleolog::Researcher.new(user: other_user, project: project_with_different_user))
        project = repo.save(Paleolog::Project.new(name: 'some project'))
        repo.save(Paleolog::Researcher.new(user: user, project: project))

        result = operation.find_all_for_user(user.id)
        assert_equal 1, result.value.size
        assert_equal project.id, result.value.first.id
      end

      it 'returns all necessary attributes' do
        project = repo.save(Paleolog::Project.new(name: 'some project'))
        repo.save(Paleolog::Researcher.new(user: user, project: project))
        result = operation.find_all_for_user(user.id)

        projects = result.value
        assert_equal 1, projects.size
        assert_equal(project.id, projects.first.id)
        assert_equal(project.name, projects.first.name)
        assert_equal(project.created_at, projects.first.created_at)
      end
    end
  end

  describe '#create' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.create({ name: 'Just a Name', user_id: user.id })
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'adds new project' do
        result = operation.create({ name: 'Some Name', user_id: user.id })
        assert_predicate result, :success?
        project = result.value
        refute_nil project.id
        assert_equal 'Some Name', project.name
      end

      it 'adds user as project manager' do
        result = operation.create({ name: 'Some Name', user_id: user.id })
        assert_predicate result, :success?

        project = result.value
        refute_nil project.id
        researchers = repo.for(Paleolog::Researcher).all_for_project(project.id)
        assert_equal 1, researchers.size
        researcher = researchers.first
        assert_equal user.id, researcher.user_id
        assert_predicate researcher, :manager
      end

      it 'adds created_at timestamp' do
        result = operation.create({ name: 'Some Name', user_id: user.id })
        assert_predicate result, :success?
        refute_nil result.value.created_at
      end

      it 'complains when user missing' do
        result = operation.create({ name: 'Some Name', user_id: nil })
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:user_id]
      end

      it 'does not complain when name not taken yet' do
        result = happy_operation.create({ name: 'Some Name', user_id: user.id })
        assert_predicate result, :success?
        assert_equal 'Some Name', result.value.name

        result = operation.create({ name: 'Other Name', user_id: user.id })
        assert_predicate result, :success?
        assert_equal 'Other Name', result.value.name
      end

      it 'complains when name is nil' do
        result = operation.create({ name: nil, user_id: user.id })
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create({ name: '  ', user_id: user.id })
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create({ name: 'Some Name', user_id: user.id })
        assert_predicate result, :success?
        refute_nil result.value

        result = operation.create({ name: 'Some Name', user_id: user.id })
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.create({ name: 'a' * (max + 1), user_id: user.id })
        assert_predicate result, :failure?
        assert_equal :too_long, result.error[:name]
      end

      it 'accepts name of max length' do
        name = 'a' * 255
        result = operation.create({ name: name, user_id: user.id })
        assert_predicate result, :success?
        assert_equal name, result.value.name
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create({ name: 'Some Name', user_id: user.id })
        assert_predicate result, :success?

        result = operation.create({ name: ' some name ', user_id: user.id })
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end
    end
  end

  describe '#rename' do
    let(:project_id) do
      result = happy_operation.create({ name: 'Some Name', user_id: user.id })
      assert_predicate result, :success?
      result.value.id
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.rename({ id: project_id, name: 'Just Another Name' })
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Project, project_id]

      result = operation.rename({ id: project_id, name: 'Just Another Name' })
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHORIZED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Project, project_id]
      end

      it 'renames project' do
        result = operation.rename({ id: project_id, name: 'Other Name' })
        assert_predicate result, :success?
        assert_equal 'Other Name', result.value.name
      end

      it 'can set the same name' do
        result = operation.rename({ id: project_id, name: 'Some Name' })
        assert_predicate result, :success?
        assert_equal 'Some Name', result.value.name
      end

      it 'complains when name is nil' do
        result = operation.rename({ id: project_id, name: nil })
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.rename({ id: project_id, name: '   ' })
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create({ name: 'Other Name', user_id: user.id })
        assert_predicate result, :success?

        result = operation.rename({ id: project_id, name: 'Other Name' })
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.rename({ id: project_id, name: 'a' * (max + 1) })
        assert_predicate result, :failure?
        assert_equal :too_long, result.error[:name]
      end

      it 'accepts name of max length' do
        name = 'a' * 255
        result = operation.rename({ id: project_id, name: name })
        assert_predicate result, :success?
        assert_equal name, result.value.name
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create({ name: 'Other Name', user_id: user.id })
        assert_predicate result, :success?

        result = operation.rename({ id: project_id, name: ' other name ' })
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end
    end
  end
end
