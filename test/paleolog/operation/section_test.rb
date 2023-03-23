# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Section do
  let(:operation) { Paleolog::Operation::Section }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:project) do
    project, errors = Paleolog::Operation::Project.create({ name: 'Project for Section' }, user_id: user.id)
    assert_predicate errors, :empty?
    project
  end
  let(:authorizer) { Minitest::Mock.new }

  after do
    Paleolog::Repo::Section.delete_all
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

      it 'creates and returns section' do
        section, errors = operation.create({ name: 'Just a Name', project_id: project.id }, authorizer: authorizer)
        refute_nil section
        assert_predicate errors, :empty?

        refute_nil section.id
        assert_equal 'Just a Name', section.name
        assert_equal project.id, section.project_id
      end

      it 'does not complain when name not taken yet' do
        _, errors = operation.create({ name: 'Some Name', project_id: project.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.create({ name: 'Other Name', project_id: project.id }, authorizer: authorizer)
        assert_predicate errors, :empty?
      end

      it 'complains when project_id is blank' do
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
        assert_equal :blank, errors[:name]
      end

      it 'complains when name is blank' do
        _, errors = operation.create({ name: '  ', project_id: project.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :blank, errors[:name]
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

      it 'allows name lenght to be of max size' do
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
    let(:existing_section) do
      section, errors = operation.create({ name: 'Some Name', project_id: project.id }, authorizer: HappyAuthorizer.new)
      assert_predicate errors, :empty?
      section
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      _, errors = operation.update({ id: existing_section.id, name: 'Just another Name' }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, errors[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Section, existing_section.id]

      _, errors = operation.update({ id: existing_section.id, name: 'Just another Name' }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Section, existing_section.id]
      end

      it 'updates and returns section' do
        section, errors = operation.update({ id: existing_section.id, name: 'Other Name' }, authorizer: authorizer)
        refute_nil section
        assert_predicate errors, :empty?

        assert_equal existing_section.id, section.id
        assert_equal 'Other Name', section.name
        assert_equal project.id, section.project_id
      end

      it 'complains when name is nil' do
        _, errors = operation.update({ id: existing_section.id, name: nil }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :blank, errors[:name]
      end

      it 'complains when name is blank' do
        _, errors = operation.update({ id: existing_section.id, name: '  ' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :blank, errors[:name]
      end

      it 'complains when name already exists' do
        _, errors = operation.create({ name: 'Another Name', project_id: project.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.update({ id: existing_section.id, name: 'Another Name' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :taken, errors[:name]
      end

      it 'complains when name with different cases already exists' do
        _, errors = operation.create({ name: 'Another Name', project_id: project.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.update({ id: existing_section.id, name: ' another name ' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal :taken, errors[:name]
      end

      it 'does not complain when name exists but in other project' do
        other_project, = Paleolog::Operation::Project.create({ name: 'Other Project for Section' }, user_id: user.id)
        _, errors = operation.create({ name: 'Another Name', project_id: other_project.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.update({ id: existing_section.id, name: 'Another Name' }, authorizer: authorizer)
        assert_predicate errors, :empty?
      end

      it 'can set the same name' do
        section, errors = operation.update({ id: existing_section.id, name: existing_section.name }, authorizer: authorizer)
        assert_predicate errors, :empty?
        assert_equal existing_section.name, section.name
      end

      it 'complains when name is too long' do
        max = 255
        _, errors = operation.update({ id: existing_section.id, name: 'a' * (max + 1) }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal ParamParam::TOO_LONG, errors[:name]
      end

      it 'allows name to be of max length' do
        max = 255
        _, errors = operation.update({ id: existing_section.id, name: 'a' * max }, authorizer: authorizer)
        assert_predicate errors, :empty?
      end
    end
  end
end
