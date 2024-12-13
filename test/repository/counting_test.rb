# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repository::Counting do
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) do
    Paleolog::Repository::Counting.new(Paleolog.db, authorizer)
  end
  let(:happy_operation) do
    happy_operation_for(Paleolog::Repository::Counting, user)
  end
  let(:happy_project_operation) do
    happy_operation_for(Paleolog::Repository::Project, user)
  end
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end
  let(:project) do
    happy_project_operation.create(name: 'Project for Counting', user_id: user.id).value
  end

  describe '#find' do
    let(:counting) do
      happy_operation.create(name: 'Test123', project_id: project.id).value
    end

    it 'requires authenticated user' do
      authorizer.expect :authenticated?, false

      result = operation.find(id: counting.id)

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthenticated?(result.error)

      authorizer.verify
    end

    it 'requires authorized user' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_view?, false, [Paleolog::Counting, counting.id]

      result = operation.find(id: counting.id)

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthorized?(result.error)

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

      it 'loads counted group and marker' do
        group = happy_operation_for(Paleolog::Repository::Group, user).create(name: 'Counted Group').value
        marker = happy_operation_for(Paleolog::Repository::Species, user).create(name: 'Marker',
                                                                                 group_id: group.id,).value
        happy_operation.update(id: counting.id, group_id: group.id, marker_id: marker.id)

        operation
          .find(id: counting.id)
          .on_success do |found_counting|
            refute_nil found_counting.group
            assert_equal group.id, found_counting.group.id
            refute_nil found_counting.marker
            assert_equal marker.id, found_counting.marker.id
          end.on_failure do |error|
            flunk("Expected counting but got #{error}")
          end
      end

      it 'returns existing counting for given project' do
        authorizer.expect :can_view?, true, [Paleolog::Counting, counting.id]

        operation.find(id: counting.id, project_id: project.id)
                 .on_success do |found_counting|
          refute_nil found_counting
          assert_equal counting.id, found_counting.id
        end.on_failure do |error|
          flunk("Expected counting but got #{error}")
        end
      end

      it 'fails for existing counting but different given project' do
        authorizer.expect :can_view?, true, [Paleolog::Counting, counting.id]

        operation.find(id: counting.id, project_id: project.id + 1)
                 .on_failure do |error|
          assert Paleolog::Operation.not_found?(error), "Expected not found error, got #{error}"
        end.on_success do |found_counting|
          flunk("Expected error, got counting #{found_counting}")
        end
      end
    end
  end

  describe '#create' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.create(name: 'Just a Name', project_id: project.id)

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthenticated?(result.error)

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Project, project.id]

      result = operation.create(name: 'Just a Name', project_id: project.id)

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthorized?(result.error)

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
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:project_id]
      end

      it 'complains when project_id is none' do
        result = operation.create(name: 'Name', project_id: Optiomist.none)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:project_id]
      end

      it 'complains when name is nil' do
        result = operation.create(name: nil, project_id: project.id)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create(name: '  ', project_id: project.id)

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]
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
        assert_equal Paleolog::Repository::Params::TOO_LONG_ERR, result.error[:name]
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
      assert Paleolog::Operation.unauthenticated?(result.error)

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Counting, existing_counting.id]

      result = operation.update(id: existing_counting.id, name: 'Other Name')

      assert_predicate result, :failure?
      assert Paleolog::Operation.unauthorized?(result.error)

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
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.update(id: existing_counting.id, name: '  ')

        assert_predicate result, :failure?
        assert_equal Paleolog::Repository::Params::MISSING_ERR, result.error[:name]
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
        assert_equal Paleolog::Repository::Params::TOO_LONG_ERR, result.error[:name]
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
