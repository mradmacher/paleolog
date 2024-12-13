# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repository::Project do
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) { Paleolog::Repository::Project.new(Paleolog.db, authorizer) }
  let(:happy_operation) { happy_operation_for(Paleolog::Repository::Project, user) }
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end

  describe '#find' do
    let(:project) { happy_operation.create(name: 'Test Project').value }

    it 'succeeds for existing project' do
      result = operation.find(id: project.id)

      assert_predicate result, :success?
    end

    it 'succeeds for existing project with fancy ID' do
      result = operation.find(id: "#{project.id}-something-fancy")

      assert_predicate result, :success?
      assert_equal project.id, result.value.id
    end

    it 'fails for not existing project' do
      result = operation.find(id: project.id + 1)

      assert_predicate result, :failure?
      assert_equal :not_found, result.error
    end

    it 'loads researchers' do
      result = operation.find(id: project.id)

      assert_predicate result, :success?
      project = result.value

      refute_empty(project.researchers, 'researchers are empty')
      assert_equal(1, project.researchers.size)

      assert_equal(user.login, project.researchers.first.user.login)
    end

    it 'loads countings' do
      happy_operation_for(Paleolog::Repository::Counting, user).create(name: 'Test Counting', project_id: project.id)

      result = operation.find(id: project.id)

      assert_predicate result, :success?
      project = result.value

      refute_empty(project.countings, 'countings are empty')
      assert_equal(1, project.countings.size)
      assert_equal('Test Counting', project.countings.first.name)
    end

    it 'loads sections' do
      happy_operation_for(Paleolog::Repository::Section, user).create(name: 'Test Section', project_id: project.id)
      result = operation.find(id: project.id)

      assert_predicate result, :success?
      project = result.value

      refute_empty(project.sections, 'sections are empty')
      assert_equal(1, project.sections.size)
      assert_equal('Test Section', project.sections.first.name)
    end
  end

  describe '#find_all' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.find_all

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthenticated?(result.error)

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :user_id, user.id
      end

      it 'returns empty collection when there are no projects' do
        result = operation.find_all

        assert_predicate result, :success?
        assert_empty result.value
      end

      it 'returns only projects user participates in' do
        other_user = Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
        other_happy_operation = happy_operation_for(Paleolog::Repository::Project, other_user)

        assert_predicate other_happy_operation.create(name: 'project1'), :success?
        assert_predicate happy_operation.create(name: 'project2'), :success?
        result = operation.find_all

        assert_equal 1, result.value.size
        assert_equal 'project2', result.value.first.name
      end

      it 'returns all necessary attributes' do
        project = happy_operation.create(name: 'some project').value
        result = operation.find_all
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

      result = operation.create(name: 'Just a Name')

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthenticated?(result.error)

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :user_id, user.id
      end

      it 'adds new project' do
        result = operation.create(name: 'Some Name')

        assert_predicate result, :success?
        refute_nil result.value
      end

      it 'adds user as project manager' do
        result = operation.create(name: 'Some Name')

        assert_predicate result, :success?
        project = result.value

        refute_nil project
        assert_equal 1, project.researchers.size
        researcher = project.researchers.first

        assert_equal user.id, researcher.user_id
        assert_predicate researcher, :manager
      end

      it 'adds created_at timestamp' do
        result = operation.create({ name: 'Some Name' })

        assert_predicate result, :success?
        refute_nil result.value.created_at
      end

      it 'complains when user missing' do
        authorizer.user_id # let's clear previously defined expectation
        authorizer.expect :user_id, nil
        result = operation.create({ name: 'Some Name' })

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:user_id]
      end

      it 'does not complain when name not taken yet' do
        result = happy_operation.create({ name: 'Some Name' })

        assert_predicate result, :success?
        assert_equal 'Some Name', result.value.name

        result = operation.create({ name: 'Other Name' })

        assert_predicate result, :success?
        assert_equal 'Other Name', result.value.name
      end

      it 'complains when name is nil' do
        result = operation.create({ name: nil })

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create({ name: '  ' })

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create({ name: 'Some Name' })

        assert_predicate result, :success?
        refute_nil result.value

        result = operation.create({ name: 'Some Name' })

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when different case name already exists' do
        result = happy_operation.create({ name: 'Some Name' })

        assert_predicate result, :success?
        refute_nil result.value

        result = operation.create({ name: 'sOme nAME' })

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.create({ name: 'a' * (max + 1) })

        assert_predicate result, :failure?
        assert_equal :too_long, result.error[:name]
      end

      it 'accepts name of max length' do
        name = 'a' * 255
        result = operation.create({ name: name })

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
    let(:project) do
      happy_operation.create({ name: 'Some Name' }).value
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.rename({ id: project.id, name: 'Just Another Name' })

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthenticated?(result.error)

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Project, project.id]

      result = operation.rename({ id: project.id, name: 'Just Another Name' })

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthorized?(result.error)

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Project, project.id]
      end

      it 'renames project' do
        result = operation.rename(id: project.id, name: 'Other Name')

        assert_predicate result, :success?
        assert_equal 'Other Name', result.value.name
      end

      it 'can set the same name' do
        result = operation.rename(id: project.id, name: 'Some Name')

        assert_predicate result, :success?
        assert_equal 'Some Name', result.value.name
      end

      it 'complains when name is nil' do
        result = operation.rename(id: project.id, name: nil)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.rename(id: project.id, name: '   ')

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Other Name', user_id: user.id)

        assert_predicate result, :success?

        result = operation.rename(id: project.id, name: 'Other Name')

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.rename(id: project.id, name: 'a' * (max + 1))

        assert_predicate result, :failure?
        assert_equal :too_long, result.error[:name]
      end

      it 'accepts name of max length' do
        name = 'a' * 255
        result = operation.rename(id: project.id, name: name)

        assert_predicate result, :success?
        assert_equal name, result.value.name
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(name: 'Other Name', user_id: user.id)

        assert_predicate result, :success?

        result = operation.rename(id: project.id, name: ' other name ')

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end
    end
  end
end
