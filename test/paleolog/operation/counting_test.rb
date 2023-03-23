# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Counting do
  let(:operation) { Paleolog::Operation::Counting }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:project) do
    project, errors = Paleolog::Operation::Project.create({ name: 'Project for Counting' }, user_id: user.id)
    assert_predicate errors, :empty?
    project
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

      _, errors = operation.create({ name: 'Just a Name', project_id: project.id }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, errors[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Project, project.id]

      _, errors = operation.create({ name: 'Just a Name', project_id: project.id }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Project, project.id]
      end

      it 'returns counting' do
        counting, errors = operation.create({ name: 'Just a Name', project_id: project.id }, authorizer: authorizer)
        refute_nil counting
        assert_predicate errors, :empty?

        refute_nil counting.id
        assert_equal 'Just a Name', counting.name
        assert_equal project.id, counting.project_id
      end

      it 'complains when project_id is nil' do
        _, errors = operation.create({ name: 'Name', project_id: nil }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal ParamParam::NON_INTEGER, errors[:project_id]
      end

      it 'complains when project_id is none' do
        _, errors = operation.create({ name: 'Name', project_id: ParamParam::Option.None }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal ParamParam::MISSING, errors[:project_id]
      end

      it 'complains when name is nil' do
        _, errors = operation.create({ name: nil, project_id: project.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal ParamParam::BLANK, errors[:name]
      end

      it 'complains when name is blank' do
        _, errors = operation.create({ name: '  ', project_id: project.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal ParamParam::BLANK, errors[:name]
      end

      it 'complains when name already exists' do
        _, errors = operation.create({ name: 'Some Name', project_id: project.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.create({ name: 'Some Name', project_id: project.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :taken, errors[:name]
      end

      it 'complains when name is too long' do
        max = 255
        _, errors = operation.create({ name: 'a' * (max + 1), project_id: project.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal ParamParam::TOO_LONG, errors[:name]
      end

      it 'accepts name with max length' do
        max = 255
        _, errors = operation.create({ name: 'a' * max, project_id: project.id }, authorizer: authorizer)
        assert_predicate errors, :empty?
      end

      it 'complains when name with different cases already exists' do
        _, errors = operation.create({ name: 'Some Name', project_id: project.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.create({ name: ' some name ', project_id: project.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :taken, errors[:name]
      end
    end
  end

  describe '#update' do
    let(:existing_counting) do
      counting, errors = operation.create({ name: 'Some Name', project_id: project.id }, authorizer: HappyAuthorizer.new)
      assert_predicate errors, :empty?
      counting
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      _, errors = operation.update({ id: existing_counting.id, name: 'Other Name' }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, errors[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Counting, existing_counting.id]

      _, errors = operation.update({ id: existing_counting.id, name: 'Other Name' }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Counting, existing_counting.id]
      end

      it 'returns counting' do
        counting, errors = operation.update({ id: existing_counting.id, name: 'Other Name' }, authorizer: authorizer)
        refute_nil counting
        assert_predicate errors, :empty?

        assert_equal existing_counting.id, counting.id
        assert_equal 'Other Name', counting.name
        assert_equal project.id, counting.project_id
      end

      it 'complains when name is nil' do
        _, errors = operation.update({ id: existing_counting.id, name: nil }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :blank, errors[:name]
      end

      it 'complains when name is blank' do
        _, errors = operation.update({ id: existing_counting.id, name: '  ' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :blank, errors[:name]
      end

      it 'complains when name already exists' do
        _, errors = operation.create({ name: 'Another Name', project_id: project.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.update({ id: existing_counting.id, name: 'Another Name' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :taken, errors[:name]
      end

      it 'complains when name with different cases already exists' do
        _, errors = operation.create({ name: 'Another Name', project_id: project.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.update({ id: existing_counting.id, name: ' another name ' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :taken, errors[:name]
      end

      it 'does not complain when name exists but in other project' do
        other_project, = Paleolog::Operation::Project.create({ name: 'Other Project for Section' }, user_id: user.id)
        _, errors = operation.create({ name: 'Another Name', project_id: other_project.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.update({ id: existing_counting.id, name: 'Another Name' }, authorizer: authorizer)
        assert_predicate errors, :empty?
      end

      it 'can set the same name' do
        counting, errors = operation.update({ id: existing_counting.id, name: existing_counting.name }, authorizer: authorizer)
        assert_predicate errors, :empty?
        assert_equal existing_counting.name, counting.name
      end

      it 'complains when name is too long' do
        max = 255
        _, errors = operation.update({ id: existing_counting.id, name: 'a' * (max + 1) }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal ParamParam::TOO_LONG, errors[:name]
      end

      it 'accepts max length name' do
        max = 255
        _, errors = operation.update({ id: existing_counting.id, name: 'a' * max }, authorizer: authorizer)
        assert_predicate errors, :empty?
      end
    end
  end
end
