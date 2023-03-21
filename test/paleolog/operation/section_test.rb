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

  after do
    Paleolog::Repo::Section.delete_all
    Paleolog::Repo::Project.delete_all
  end

  describe '#create' do
    it 'rejects missing user' do
      _, errors = operation.create({ name: 'Just a Name', project_id: project.id }, user_id: nil)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
    end

    it 'rejects guest access' do
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123'))
      _, errors = operation.create({ name: 'Just a Name', project_id: project.id }, user_id: other_user.id)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
    end

    it 'rejects user observing the project' do
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123'))
      Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: other_user, project: project))

      _, errors = operation.create({ name: 'Just a Name', project_id: project.id }, user_id: other_user.id)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
    end

    it 'returns section' do
      section, errors = operation.create({ name: 'Just a Name', project_id: project.id }, user_id: user.id)
      refute_nil section
      assert_predicate errors, :empty?

      refute_nil section.id
      assert_equal 'Just a Name', section.name
      assert_equal project.id, section.project_id
    end

    it 'does not complain when name not taken yet' do
      _, errors = operation.create({ name: 'Some Name', project_id: project.id }, user_id: user.id)
      assert_predicate errors, :empty?

      _, errors = operation.create({ name: 'Other Name', project_id: project.id }, user_id: user.id)
      assert_predicate errors, :empty?
    end

    it 'complains when project_id blank' do
      _, errors = operation.create({ name: 'Name', project_id: nil }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal ParamParam::NON_INTEGER, errors[:project_id]

      _, errors = operation.create({ name: 'Name', project_id: ParamParam::Option.None }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal ParamParam::MISSING, errors[:project_id]
    end

    it 'complains when name is blank' do
      _, errors = operation.create({ name: nil, project_id: project.id }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]

      _, errors = operation.create({ name: '  ', project_id: project.id }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]
    end

    it 'complains when name already exists' do
      _, errors = operation.create({ name: 'Some Name', project_id: project.id }, user_id: user.id)
      assert_predicate errors, :empty?

      _, errors = operation.create({ name: 'Some Name', project_id: project.id }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
    end

    it 'complains when name is too long' do
      max = 255
      _, errors = operation.create({ name: 'a' * (max + 1), project_id: project.id }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal ParamParam::TOO_LONG, errors[:name]

      _, errors = operation.create({ name: 'a' * max, project_id: project.id }, user_id: user.id)
      assert_predicate errors, :empty?
    end

    it 'complains when name with different cases already exists' do
      _, errors = operation.create({ name: 'Some Name', project_id: project.id }, user_id: user.id)
      assert_predicate errors, :empty?

      _, errors = operation.create({ name: ' some name ', project_id: project.id }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
    end
  end

  describe '#rename' do
    let(:section_id) do
      section, errors = operation.create({ name: 'Some Name', project_id: project.id }, user_id: user.id)
      assert_predicate errors, :empty?
      section.id
    end

    it 'rejects missing user' do
      _, errors = operation.rename({ id: section_id, name: 'Other Name' }, user_id: nil)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
    end

    it 'rejects guest access' do
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123'))
      _, errors = operation.rename({ id: section_id, name: 'Other Name' }, user_id: other_user.id)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
    end

    it 'rejects user observing the project' do
      other_user = Paleolog::Repo.save(Paleolog::User.new(login: 'other user', password: 'test123'))
      Paleolog::Repo.save(Paleolog::ResearchParticipation.new(user: other_user, project: project))

      _, errors = operation.rename({ id: section_id, name: 'Other Name' }, user_id: other_user.id)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]
    end

    it 'returns section' do
      section, errors = operation.rename({ id: section_id, name: 'Other Name' }, user_id: user.id)
      refute_nil section
      assert_predicate errors, :empty?

      assert_equal section_id, section.id
      assert_equal 'Other Name', section.name
      assert_equal project.id, section.project_id
    end

    it 'complains when name is blank' do
      _, errors = operation.rename({ id: section_id, name: nil }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]

      _, errors = operation.rename({ id: section_id, name: '  ' }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :blank, errors[:name]
    end

    it 'complains when name already exists' do
      _, errors = operation.create({ name: 'Another Name', project_id: project.id }, user_id: user.id)
      assert_predicate errors, :empty?

      _, errors = operation.rename({ id: section_id, name: 'Another Name' }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
    end

    it 'complains when name with different cases already exists' do
      _, errors = operation.create({ name: 'Another Name', project_id: project.id }, user_id: user.id)
      assert_predicate errors, :empty?

      _, errors = operation.rename({ id: section_id, name: ' another name ' }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:name]
    end

    it 'does not complain when name exists but in other project' do
      other_project, = Paleolog::Operation::Project.create({ name: 'Other Project for Section' }, user_id: user.id)
      _, errors = operation.create({ name: 'Another Name', project_id: other_project.id }, user_id: user.id)
      assert_predicate errors, :empty?

      _, errors = operation.rename({ id: section_id, name: 'Another Name' }, user_id: user.id)
      assert_predicate errors, :empty?
    end

    it 'can set the same name' do
      section, errors = operation.rename({ id: section_id, name: 'Some Name' }, user_id: user.id)
      assert_predicate errors, :empty?
      assert_equal 'Some Name', section.name
    end

    it 'complains when name is too long' do
      max = 255
      _, errors = operation.rename({ id: section_id, name: 'a' * (max + 1) }, user_id: user.id)
      refute_predicate errors, :empty?
      assert_equal ParamParam::TOO_LONG, errors[:name]

      _, errors = operation.rename({ id: section_id, name: 'a' * max }, user_id: user.id)
      assert_predicate errors, :empty?
    end
  end
end
