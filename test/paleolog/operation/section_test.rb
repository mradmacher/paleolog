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
    it 'does not complain when name not taken yet' do
      result = operation.create(name: 'Some Name', project_id: project.id)
      assert_predicate result, :success?

      result = operation.create(name: 'Other Name', project_id: project.id)
      assert_predicate result, :success?
    end

    it 'complains when group_id blank' do
      result = operation.create(name: 'Name', project_id: nil)
      assert_predicate result, :failure?
      assert_equal ParamParam::NON_INTEGER, result.error[:project_id]

      result = operation.create(name: 'Name', project_id: ParamParam::Option.None)
      assert_predicate result, :failure?
      assert_equal ParamParam::MISSING, result.error[:project_id]
    end

    it 'complains when name is blank' do
      result = operation.create(name: nil, project_id: project.id)
      assert_predicate result, :failure?
      assert_equal :blank, result.error[:name]

      result = operation.create(name: '  ', project_id: project.id)
      assert_predicate result, :failure?
      assert_equal :blank, result.error[:name]
    end

    it 'complains when name already exists' do
      result = operation.create(name: 'Some Name', project_id: project.id)
      assert_predicate result, :success?

      result = operation.create(name: 'Some Name', project_id: project.id)
      assert_predicate result, :failure?
      assert_equal :taken, result.error[:name]
    end

    it 'complains when name is too long' do
      max = 255
      result = operation.create(name: 'a' * (max + 1), project_id: project.id)
      assert_predicate result, :failure?
      assert_equal ParamParam::TOO_LONG, result.error[:name]

      result = operation.create(name: 'a' * max, project_id: project.id)
      assert_predicate result, :success?
    end

    it 'complains when name with different cases already exists' do
      result = operation.create(name: 'Some Name', project_id: project.id)
      assert_predicate result, :success?

      result = operation.create(name: ' some name ', project_id: project.id)
      assert_predicate result, :failure?
      assert_equal :taken, result.error[:name]
    end
  end
end
