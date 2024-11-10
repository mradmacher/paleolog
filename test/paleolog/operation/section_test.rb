# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Section do
  let(:repo) { Paleolog::Repo }
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) { Paleolog::Operation::Section.new(repo, authorizer) }
  let(:happy_operation) { happy_operation_for(Paleolog::Operation::Section, user) }
  let(:user) do
    repo.find(
      Paleolog::User,
      repo.save(Paleolog::User.new(login: 'test', password: 'test123')),
    )
  end
  let(:project) do
    happy_operation_for(Paleolog::Operation::Project, user).create(
      name: 'Project for Section',
    ).value
  end

  after do
    repo.for(Paleolog::Section).delete_all
    repo.for(Paleolog::Researcher).delete_all
    repo.for(Paleolog::Project).delete_all
    repo.for(Paleolog::User).delete_all
  end

  describe '#all_for_project' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.all_for_project(project_id: project.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_view?, false, [Paleolog::Project, project.id]

      result = operation.all_for_project(project_id: project.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHORIZED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_view?, true, [Paleolog::Project, project.id]
      end

      it 'requires project_id param' do
        result = operation.all_for_project({})

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::MISSING, result.error[:project_id]
      end

      it 'returns all project sections' do
        result = happy_operation.create(name: 'Test111', project_id: project.id)

        assert_predicate result, :success?
        section1 = result.value

        result = happy_operation.create(name: 'Test222', project_id: project.id)

        assert_predicate result, :success?
        section2 = result.value

        result = operation.all_for_project(project_id: project.id)

        assert_predicate result, :success?
        sections = result.value

        assert_equal 2, sections.size
        assert_equal [section1.id, section2.id], sections.map(&:id)
      end
    end
  end

  describe '#find' do
    let(:section) { happy_operation.create(name: 'Test123', project_id: project.id).value }

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.find(id: section.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_view?, false, [Paleolog::Section, section.id]

      result = operation.find(id: section.id)

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHORIZED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_view?, true, [Paleolog::Section, section.id]
      end

      it 'returns counting' do
        result = operation.find(id: section.id)

        assert_predicate result, :success?

        found_section = result.value

        refute_nil found_section

        refute_nil found_section.id
        assert_equal found_section.id, section.id
        assert_equal found_section.name, section.name
        assert_equal found_section.project_id, section.project_id
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

      it 'creates and returns section' do
        result = operation.create(
          { name: 'Just a Name', project_id: project.id },
        )

        assert_predicate result, :success?
        section = result.value

        refute_nil section

        assert_equal 'Just a Name', section.name
        assert_equal project.id, section.project_id
      end

      it 'does not complain when name not taken yet' do
        result = happy_operation.create(name: 'Some Name', project_id: project.id)

        assert_predicate result, :success?

        result = operation.create(name: 'Other Name', project_id: project.id)

        assert_predicate result, :success?
      end

      it 'complains when project_id is blank' do
        result = operation.create(name: 'Name', project_id: nil)

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:project_id]
      end

      it 'complains when project_id is none' do
        result = operation.create(
          { name: 'Name', project_id: Optiomist.none },
        )

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::MISSING, result.error[:project_id]
      end

      it 'complains when name is nil' do
        result = operation.create(name: nil, project_id: project.id)

        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create(name: '  ', project_id: project.id)

        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Some Name', project_id: project.id)

        assert_predicate result, :success?

        result = operation.create(name: 'Some Name', project_id: project.id)

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.create(name: 'a' * (max + 1), project_id: project.id)

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:name]
      end

      it 'allows name lenght to be of max size' do
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
    let(:existing_section) do
      happy_operation.create(name: 'Some Name', project_id: project.id).value
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.update(
        { id: existing_section.id, name: 'Just another Name' },
      )

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Section, existing_section.id]

      result = operation.update(
        { id: existing_section.id, name: 'Just another Name' },
      )

      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHORIZED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Section, existing_section.id]
      end

      it 'updates and returns section' do
        result = operation.update(
          { id: existing_section.id, name: 'Other Name' },
        )

        assert_predicate result, :success?
        section = result.value

        refute_nil section

        assert_equal existing_section.id, section.id
        assert_equal 'Other Name', section.name
        assert_equal project.id, section.project_id
      end

      it 'complains when name is nil' do
        result = operation.update(
          { id: existing_section.id, name: nil },
        )

        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.update(
          { id: existing_section.id, name: '  ' },
        )

        assert_predicate result, :failure?
        assert_equal :blank, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Another Name', project_id: project.id)

        assert_predicate result, :success?

        result = operation.update(id: existing_section.id, name: 'Another Name')

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(name: 'Another Name', project_id: project.id)

        assert_predicate result, :success?

        result = operation.update(id: existing_section.id, name: ' another name ')

        assert_predicate result, :failure?
        assert_equal :taken, result.error[:name]
      end

      it 'does not complain when name exists but in other project' do
        other_project = happy_operation_for(Paleolog::Operation::Project, user)
                        .create(name: 'Other Project for Section')
                        .value
        result = happy_operation.create(
          name: 'Another Name', project_id: other_project.id,
        )

        assert_predicate result, :success?

        result = operation.update(id: existing_section.id, name: 'Another Name')

        assert_predicate result, :success?
      end

      it 'can set the same name' do
        result = operation.update(id: existing_section.id, name: existing_section.name)

        assert_predicate result, :success?
        assert_equal existing_section.name, result.value.name
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.update(id: existing_section.id, name: 'a' * (max + 1))

        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:name]
      end

      it 'allows name to be of max length' do
        name = 'a' * 255
        result = operation.update(id: existing_section.id, name: name)

        assert_predicate result, :success?
        assert_equal name, result.value.name
      end
    end
  end
end
