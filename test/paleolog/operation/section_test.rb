# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Section do
  let(:operation) { Paleolog::Operation::Section }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:project) { Paleolog::Operation::Project.create(name: 'Project for Section', user_id: user.id).first }

  after do
    Paleolog::Repo::Section.delete_all
    Paleolog::Repo::Project.delete_all
  end

  describe '#create' do
    it 'returns section' do
      section, errors = operation.create(name: 'Some Name', project_id: project.id)
      refute_predicate section, :nil?
      assert_predicate errors, :empty?

      refute_nil section.id
      assert_equal 'Some Name', section.name
      assert_equal project.id, section.project_id
    end

    it 'does not complain when name not taken yet' do
      _, errors = operation.create(name: 'Some Name', project_id: project.id)
      assert_predicate errors, :empty?

      _, errors = operation.create(name: 'Other Name', project_id: project.id)
      assert_predicate errors, :empty?
    end

    it 'complains when project_id blank' do
      _, errors = operation.create(name: 'Name', project_id: nil)
      refute_predicate errors, :empty?
      assert_equal ParamParam::NON_INTEGER, errors[:project_id]

      _, errors = operation.create(name: 'Name', project_id: ParamParam::Option.None)
      refute_predicate errors, :empty?
      assert_equal ParamParam::MISSING, errors[:project_id]
    end

    it 'complains when name is blank' do
      _, errors = operation.create(name: nil, project_id: project.id)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]

      _, errors = operation.create(name: '  ', project_id: project.id)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]
    end

    it 'complains when name already exists' do
      _, errors = operation.create(name: 'Some Name', project_id: project.id)
      assert_predicate errors, :empty?

      _, errors = operation.create(name: 'Some Name', project_id: project.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
    end

    it 'complains when name is too long' do
      max = 255
      _, errors = operation.create(name: 'a' * (max + 1), project_id: project.id)
      refute_predicate errors, :empty?
      assert_equal ParamParam::TOO_LONG, errors[:name]

      _, errors = operation.create(name: 'a' * max, project_id: project.id)
      assert_predicate errors, :empty?
    end

    it 'complains when name with different cases already exists' do
      _, errors = operation.create(name: 'Some Name', project_id: project.id)
      assert_predicate errors, :empty?

      _, errors = operation.create(name: ' some name ', project_id: project.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
    end
  end

  describe '#rename' do
    let(:section_id) { operation.create(name: 'Some Name', project_id: project.id).first.id }

    before { refute_nil section_id }

    it 'returns section' do
      section, errors = operation.rename(section_id, name: 'Other Name')
      refute_predicate section, :nil?
      assert_predicate errors, :empty?

      assert_equal section_id, section.id
      assert_equal 'Other Name', section.name
      assert_equal project.id, section.project_id
    end

    it 'complains when name is blank' do
      _, errors = operation.rename(section_id, name: nil)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]

      _, errors = operation.rename(section_id, name: '  ')
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]
    end

    it 'complains when name already exists' do
      _, errors = operation.create(name: 'Another Name', project_id: project.id)
      assert_predicate errors, :empty?

      _, errors = operation.rename(section_id, name: 'Another Name')
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
    end

    it 'complains when name with different cases already exists' do
      _, errors = operation.create(name: 'Another Name', project_id: project.id)
      assert_predicate errors, :empty?

      _, errors = operation.rename(section_id, name: ' another name ')
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
    end

    it 'does not complain when name exists but in other project' do
      other_project, _ = Paleolog::Operation::Project.create(name: 'Other Project for Section', user_id: user.id)
      _, errors = operation.create(name: 'Another Name', project_id: other_project.id)
      assert_predicate errors, :empty?

      _, errors = operation.rename(section_id, name: 'Another Name')
      assert_predicate errors, :empty?
    end

    it 'can set the same name' do
      section, errors = operation.rename(section_id, name: 'Some Name')
      assert_predicate errors, :empty?
      assert_equal 'Some Name', section.name
    end

    it 'complains when name is too long' do
      max = 255
      _, errors = operation.rename(section_id, name: 'a' * (max + 1))
      refute_predicate errors, :empty?
      assert_equal ParamParam::TOO_LONG, errors[:name]

      _, errors = operation.rename(section_id, name: 'a' * max)
      assert_predicate errors, :empty?
    end

  end
end
