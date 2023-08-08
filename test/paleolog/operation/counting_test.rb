# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Counting do
  let(:operation) { Paleolog::Operation::Counting }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:project) do
    result = Paleolog::Operation::Project.create(
      { name: 'Project for Counting', user_id: user.id },
      authorizer: HappyAuthorizer.new,
    )
    assert_predicate result, :success?
    result.value
  end
  let(:authorizer) { Minitest::Mock.new }

  after do
    Paleolog::Repo::Counting.delete_all
    Paleolog::Repo::Researcher.delete_all
    Paleolog::Repo::Project.delete_all
    Paleolog::Repo::User.delete_all
  end

  describe '#create' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.create(
        { name: 'Just a Name', project_id: project.id },
        authorizer: authorizer,
      )
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Project, project.id]

      result = operation.create(
        { name: 'Just a Name', project_id: project.id },
        authorizer: authorizer,
      )
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
        result = operation.create(
          { name: 'Just a Name', project_id: project.id },
          authorizer: authorizer,
        )
        assert_predicate result, :success?

        counting = result.value
        refute_nil counting

        refute_nil counting.id
        assert_equal 'Just a Name', counting.name
        assert_equal project.id, counting.project_id
      end

      it 'complains when project_id is nil' do
        result = operation.create(
          { name: 'Name', project_id: nil },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::NON_INTEGER, result.error[:project_id]
      end

      it 'complains when project_id is none' do
        result = operation.create(
          { name: 'Name', project_id: ParamParam::Option.None },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::MISSING, result.error[:project_id]
      end

      it 'complains when name is nil' do
        result = operation.create(
          { name: nil, project_id: project.id },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::BLANK, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create(
          { name: '  ', project_id: project.id },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::BLANK, result.error[:name]
      end

      it 'complains when name already exists' do
        result = operation.create(
          { name: 'Some Name', project_id: project.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_predicate result, :success?

        result = operation.create(
          { name: 'Some Name', project_id: project.id },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name is too long' do
        name = 'a' * (255 + 1)
        result = operation.create(
          { name: name, project_id: project.id },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::TOO_LONG, result.error[:name]
      end

      it 'accepts name with max length' do
        max = 255
        result = operation.create(
          { name: 'a' * max, project_id: project.id },
          authorizer: authorizer,
        )
        assert_predicate result, :success?
      end

      it 'complains when name with different cases already exists' do
        result = operation.create(
          { name: 'Some Name', project_id: project.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_predicate result, :success?

        result = operation.create(
          { name: ' some name ', project_id: project.id },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end
    end
  end

  describe '#update' do
    let(:existing_counting) do
      result = operation.create(
        { name: 'Some Name', project_id: project.id },
        authorizer: HappyAuthorizer.new,
      )
      assert_predicate result, :success?
      result.value
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.update(
        { id: existing_counting.id, name: 'Other Name' },
        authorizer: authorizer,
      )
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Counting, existing_counting.id]

      result = operation.update(
        { id: existing_counting.id, name: 'Other Name' },
        authorizer: authorizer,
      )
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
        result = operation.update(
          { id: existing_counting.id, name: 'Other Name' },
          authorizer: authorizer,
        )
        assert_predicate result, :success?

        counting = result.value
        refute_nil counting

        assert_equal existing_counting.id, counting.id
        assert_equal 'Other Name', counting.name
        assert_equal project.id, counting.project_id
      end

      it 'complains when name is nil' do
        result = operation.update(
          { id: existing_counting.id, name: nil },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.update(
          { id: existing_counting.id, name: '  ' },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = operation.create(
          { name: 'Another Name', project_id: project.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_predicate result, :success?

        result = operation.update(
          { id: existing_counting.id, name: 'Another Name' },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name with different cases already exists' do
        result = operation.create(
          { name: 'Another Name', project_id: project.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_predicate result, :success?

        result = operation.update(
          { id: existing_counting.id, name: ' another name ' },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'does not complain when name exists but in other project' do
        other_project = Paleolog::Operation::Project.create(
          { name: 'Other Project for Section', user_id: user.id },
          authorizer: HappyAuthorizer.new,
        ).value
        result = operation.create(
          { name: 'Another Name', project_id: other_project.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_predicate result, :success?

        result = operation.update(
          { id: existing_counting.id, name: 'Another Name' },
          authorizer: authorizer,
        )
        assert_predicate result, :success?
      end

      it 'can set the same name' do
        result = operation.update(
          { id: existing_counting.id, name: existing_counting.name },
          authorizer: authorizer,
        )
        assert_predicate result, :success?
        assert_equal existing_counting.name, result.value.name
      end

      it 'complains when name is too long' do
        name = 'a' * (255 + 1)
        result = operation.update(
          { id: existing_counting.id, name: name },
          authorizer: authorizer,
        )
        assert_predicate result, :failure?
        assert_equal ParamParam::TOO_LONG, result.error[:name]
      end

      it 'accepts max length name' do
        name = 'a' * 255
        result = operation.update(
          { id: existing_counting.id, name: name },
          authorizer: authorizer,
        )
        assert_predicate result, :success?
      end
    end
  end
end
