# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Counting do
  let(:repo) { Paleolog::Repo }
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) do
    Paleolog::Operation::Counting.new(repo, authorizer)
  end
  let(:happy_operation) do
    happy_operation_for(Paleolog::Operation::Counting, user)
  end
  let(:happy_project_operation) do
    happy_operation_for(Paleolog::Operation::Project, user)
  end
  let(:user) do
    id = repo.save(Paleolog::User.new(login: 'test', password: 'test123'))
    repo.find(Paleolog::User, id)
  end
  let(:project) do
    happy_project_operation.create(name: 'Project for Counting', user_id: user.id).value
  end

  after do
    repo.for(Paleolog::Counting).delete_all
    repo.for(Paleolog::Researcher).delete_all
    repo.for(Paleolog::Project).delete_all
    repo.for(Paleolog::User).delete_all
  end

  describe '#find' do
    let(:counting) do
      happy_operation.create(name: 'Test123', project_id: project.id).value
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.find(id: counting.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_view?, false, [Paleolog::Counting, counting.id]

      result = operation.find(id: counting.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHORIZED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_view?, true, [Paleolog::Counting, counting.id]
      end

      it 'returns counting' do
        result = operation.find(id: counting.id)

        assert_predicate result, :success?

        found_counting = result.value

        refute_nil found_counting

        refute_nil found_counting.id
        assert_equal found_counting.id, counting.id
        assert_equal found_counting.name, counting.name
        assert_equal found_counting.project_id, counting.project_id
      end
    end
  end

  describe '#create' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.create(name: 'Just a Name', project_id: project.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Project, project.id]

      result = operation.create(name: 'Just a Name', project_id: project.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHORIZED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Project, project.id]
      end

      it 'returns counting' do
        result = operation.create(name: 'Just a Name', project_id: project.id)

        assert_predicate result, :success?

        counting = result.value

        refute_nil counting

        assert_equal 'Just a Name', counting.name
        assert_equal project.id, counting.project_id
      end

      it 'complains when project_id is nil' do
        result = operation.create(name: 'Name', project_id: nil)

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:project_id]
      end

      it 'complains when project_id is none' do
        result = operation.create(name: 'Name', project_id: Optiomist.none)

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::MISSING, result.error[:project_id]
      end

      it 'complains when name is nil' do
        result = operation.create(name: nil, project_id: project.id)

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::BLANK, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create(name: '  ', project_id: project.id)

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::BLANK, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Some Name', project_id: project.id)

        assert_predicate result, :success?

        result = operation.create(name: 'Some Name', project_id: project.id)

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name is too long' do
        name = 'a' * (255 + 1)
        result = operation.create(name: name, project_id: project.id)

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:name]
      end

      it 'accepts name with max length' do
        max = 255
        result = operation.create(name: 'a' * max, project_id: project.id)

        assert_predicate result, :success?
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(name: 'Some Name', project_id: project.id)

        assert_predicate result, :success?

        result = operation.create(name: ' some name ', project_id: project.id)

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end
    end
  end

  describe '#update' do
    let(:existing_counting) do
      happy_operation.create(name: 'Some Name', project_id: project.id).value
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.update(id: existing_counting.id, name: 'Other Name')

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Counting, existing_counting.id]

      result = operation.update(id: existing_counting.id, name: 'Other Name')

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHORIZED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Counting, existing_counting.id]
      end

      it 'returns counting' do
        result = operation.update(id: existing_counting.id, name: 'Other Name')

        assert_predicate result, :success?
        counting = result.value

        refute_nil counting

        assert_equal existing_counting.id, counting.id
        assert_equal 'Other Name', counting.name
        assert_equal project.id, counting.project_id
      end

      it 'complains when name is nil' do
        result = operation.update(id: existing_counting.id, name: nil)

        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.update(id: existing_counting.id, name: '  ')

        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Another Name', project_id: project.id)

        assert_predicate result, :success?

        result = operation.update(id: existing_counting.id, name: 'Another Name')

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(name: 'Another Name', project_id: project.id)

        assert_predicate result, :success?

        result = operation.update(id: existing_counting.id, name: ' another name ')

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'does not complain when name exists but in other project' do
        other_project = happy_project_operation.create(
          { name: 'Other Project for Section', user_id: user.id },
        ).value
        result = happy_operation.create(name: 'Another Name', project_id: other_project.id)

        assert_predicate result, :success?

        result = operation.update(id: existing_counting.id, name: 'Another Name')

        assert_predicate result, :success?
      end

      it 'can set the same name' do
        result = operation.update(id: existing_counting.id, name: existing_counting.name)

        assert_predicate result, :success?
        counting = result.value

        assert_equal existing_counting.name, counting.name
      end

      it 'complains when name is too long' do
        name = 'a' * (255 + 1)
        result = operation.update(
          { id: existing_counting.id, name: name },
        )

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:name]
      end

      it 'accepts max length name' do
        name = 'a' * 255
        result = operation.update(
          { id: existing_counting.id, name: name },
        )

        assert_predicate result, :success?
      end
    end
  end
end
