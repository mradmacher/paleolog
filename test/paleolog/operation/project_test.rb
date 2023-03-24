# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Project do
  let(:operation) { Paleolog::Operation::Project }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:authorizer) { Minitest::Mock.new }

  after do
    Paleolog::Repo::Project.delete_all
    Paleolog::Repo::Researcher.delete_all
    Paleolog::Repo::User.delete_all
  end

  describe '#find_all_for_user' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      _, errors = operation.find_all_for_user(user.id, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, errors[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'returns empty collection when there are no projects' do
        projects, errors = operation.find_all_for_user(user.id, authorizer: authorizer)
        assert_predicate errors, :empty?
        assert_empty projects
      end

      it 'returns only projects user participates in' do
        project_with_different_user = Paleolog::Repo.save(Paleolog::Project.new(name: 'project1'))
        other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other test', password: 'test123'))
        Paleolog::Repo.save(Paleolog::Project.new(name: 'project2'))
        Paleolog::Repo.save(Paleolog::Researcher.new(user: other_user, project: project_with_different_user))
        project = Paleolog::Repo.save(Paleolog::Project.new(name: 'some project'))
        Paleolog::Repo.save(Paleolog::Researcher.new(user: user, project: project))

        projects, = operation.find_all_for_user(user.id, authorizer: authorizer)
        assert_equal 1, projects.size
        assert_equal project.id, projects.first.id
      end

      it 'returns all necessary attributes' do
        project = Paleolog::Repo.save(Paleolog::Project.new(name: 'some project'))
        Paleolog::Repo.save(Paleolog::Researcher.new(user: user, project: project))
        projects, = operation.find_all_for_user(user.id, authorizer: authorizer)

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

      _, errors = operation.create({ name: 'Just a Name', user_id: user.id }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, errors[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'adds new project' do
        project, errors = operation.create({ name: 'Some Name', user_id: user.id }, authorizer: authorizer)
        assert_predicate errors, :empty?
        refute_nil project.id
        assert_equal 'Some Name', project.name
      end

      it 'adds user as project manager' do
        project, errors = operation.create({ name: 'Some Name', user_id: user.id }, authorizer: authorizer)

        assert_predicate errors, :empty?
        refute_nil project.id
        researchers = Paleolog::Repo::Researcher.all_for_project(project.id)
        assert_equal 1, researchers.size
        researcher = researchers.first
        assert_equal user.id, researcher.user_id
        assert_predicate researcher, :manager
      end

      it 'adds created_at timestamp' do
        project, errors = operation.create({ name: 'Some Name', user_id: user.id }, authorizer: authorizer)
        assert_predicate errors, :empty?
        refute_nil project.created_at
      end

      it 'complains when user missing' do
        project, errors = operation.create({ name: 'Some Name', user_id: nil }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal ParamParam::NON_INTEGER, errors[:user_id]
        assert_nil project
      end

      it 'does not complain when name not taken yet' do
        project, errors = operation.create({ name: 'Some Name', user_id: user.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?
        assert_equal 'Some Name', project.name

        project, errors = operation.create({ name: 'Other Name', user_id: user.id }, authorizer: authorizer)
        assert_predicate errors, :empty?
        assert_equal 'Other Name', project.name
      end

      it 'complains when name is nil' do
        project, errors = operation.create({ name: nil, user_id: user.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :blank, errors[:name]
        assert_nil project
      end

      it 'complains when name is blank' do
        project, errors = operation.create({ name: '  ', user_id: user.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :blank, errors[:name]
        assert_nil project
      end

      it 'complains when name already exists' do
        project, errors = operation.create({ name: 'Some Name', user_id: user.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?
        refute_nil project

        project, errors = operation.create({ name: 'Some Name', user_id: user.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :taken, errors[:name]
        assert_nil project
      end

      it 'complains when name is too long' do
        max = 255
        project, errors = operation.create({ name: 'a' * (max + 1), user_id: user.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :too_long, errors[:name]
        assert_nil project
      end

      it 'accepts name of max length' do
        max = 255
        project, errors = operation.create({ name: 'a' * max, user_id: user.id }, authorizer: authorizer)
        assert_predicate errors, :empty?
        refute_nil project
      end

      it 'complains when name with different cases already exists' do
        _, errors = operation.create({ name: 'Some Name', user_id: user.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.create({ name: ' some name ', user_id: user.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :taken, errors[:name]
      end
    end
  end

  describe '#rename' do
    let(:project_id) do
      project, errors = operation.create({ name: 'Some Name', user_id: user.id }, authorizer: HappyAuthorizer.new)
      assert_predicate errors, :empty?
      project.id
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      _, errors = operation.rename({ id: project_id, name: 'Just Another Name' }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, errors[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Project, project_id]

      _, errors = operation.rename({ id: project_id, name: 'Just Another Name' }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Project, project_id]
      end

      it 'renames project' do
        project, errors = operation.rename({ id: project_id, name: 'Other Name' }, authorizer: authorizer)
        assert_predicate errors, :empty?
        assert_equal 'Other Name', project.name
      end

      it 'can set the same name' do
        project, errors = operation.rename({ id: project_id, name: 'Some Name' }, authorizer: authorizer)
        assert_predicate errors, :empty?
        assert_equal 'Some Name', project.name
      end

      it 'complains when name is nil' do
        project, errors = operation.rename({ id: project_id, name: nil }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :blank, errors[:name]
        assert_nil project
      end

      it 'complains when name is blank' do
        project, errors = operation.rename({ id: project_id, name: '   ' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :blank, errors[:name]
        assert_nil project
      end

      it 'complains when name already exists' do
        _, errors = operation.create({ name: 'Other Name', user_id: user.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        project, errors = operation.rename({ id: project_id, name: 'Other Name' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :taken, errors[:name]
        assert_nil project
      end

      it 'complains when name is too long' do
        max = 255
        project, errors = operation.rename({ id: project_id, name: 'a' * (max + 1) }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :too_long, errors[:name]
        assert_nil project
      end

      it 'accepts name of max length' do
        max = 255
        project, errors = operation.rename({ id: project_id, name: 'a' * max }, authorizer: authorizer)
        assert_predicate errors, :empty?
        assert_equal 'a' * max, project.name
      end

      it 'complains when name with different cases already exists' do
        _, errors = operation.create({ name: 'Other Name', user_id: user.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.rename({ id: project_id, name: ' other name ' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :taken, errors[:name]
      end
    end
  end
end
