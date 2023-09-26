# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Sample do
  let(:repo) { Paleolog::Repo }
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) { Paleolog::Operation::Sample.new(repo, authorizer) }
  let(:happy_operation) { Paleolog::Operation::Sample.new(repo, HappyAuthorizer.new(user)) }
  let(:user) { repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:project) do
    Paleolog::Operation::Project.new(repo, HappyAuthorizer.new(user)).create(
      name: 'Project for Section',
    ).value
  end
  let(:section) do
    Paleolog::Operation::Section.new(repo, HappyAuthorizer.new(user)).create(
      name: 'Section for Sample', project_id: project.id,
    ).value
  end

  after do
    repo.for(Paleolog::Sample).delete_all
    repo.for(Paleolog::Section).delete_all
    repo.for(Paleolog::Researcher).delete_all
    repo.for(Paleolog::Project).delete_all
  end

  describe '#create' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.create(name: 'Some Name', section_id: section.id)
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Section, section.id]

      result = operation.create(name: 'Some Name', section_id: section.id)
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHORIZED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Section, section.id]
      end

      it 'increases rank for each new sample' do
        sample = happy_operation.create(name: 'Name1', section_id: section.id).value
        assert_equal 1, sample.rank

        sample = happy_operation.create(name: 'Name2', section_id: section.id).value
        assert_equal 2, sample.rank

        sample = happy_operation.create(name: 'Name3', section_id: section.id).value
        assert_equal 3, sample.rank
      end

      it 'increases rank in the scope of a section' do
        other_section =
          Paleolog::Operation::Section.new(repo, HappyAuthorizer.new(user)).create(
            name: 'Other Section for Sample', project_id: project.id,
          ).value

        sample = happy_operation.create(name: 'Name1', section_id: section.id).value
        assert_equal 1, sample.rank

        sample = happy_operation.create(name: 'Name2', section_id: other_section.id).value
        assert_equal 1, sample.rank
      end

      it 'complains when section_id nil' do
        result = operation.create(name: 'Name', section_id: nil)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:section_id]
      end

      it 'complains when section_id missing' do
        result = operation.create(name: 'Name')
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::MISSING, result.error[:section_id]
      end

      it 'complains when name is nil' do
        result = operation.create(name: nil, section_id: section.id)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::BLANK, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.create(name: '  ', section_id: section.id)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::BLANK, result.error[:name]
      end

      it 'complains when name is missing' do
        result = operation.create(section_id: section.id)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::MISSING, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(name: 'Some Name', section_id: section.id)
        assert_predicate result, :success?

        result = operation.create(name: 'Some Name', section_id: section.id)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::TAKEN, result.error[:name]
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(name: 'Some Name', section_id: section.id)
        assert_predicate result, :success?

        result = operation.create(name: ' some name ', section_id: section.id)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::TAKEN, result.error[:name]
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.create(name: 'a' * (max + 1), section_id: section.id)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:name]
      end

      it 'accepts max length name' do
        name = 'a' * 255
        result = operation.create(name: name, section_id: section.id)
        assert_predicate result, :success?
        assert_equal name, result.value.name
      end

      it 'requires numerical weight' do
        ['a', '#', '34a', 'a34'].each do |value|
          result = happy_operation.create(section_id: section.id, weight: value)
          assert_predicate result, :failure?
          assert_equal Paleolog::Operation::Params::NON_DECIMAL, result.error[:weight]
        end
      end

      it 'converts blank weight to nil' do
        sample = happy_operation.create(name: 'Name1', section_id: section.id, weight: '').value
        assert_nil sample.weight
      end

      it 'accepts weight passed as string' do
        result = operation.create(name: 'Name', section_id: section.id, weight: '1.3')
        assert_predicate result, :success?
        assert_in_delta(1.3, result.value.weight)
      end

      it 'accepts weight passed as decimal' do
        result = operation.create(name: 'Name', section_id: section.id, weight: 1.3)
        assert_predicate result, :success?
        assert_in_delta(1.3, result.value.weight)
      end

      it 'accepts weight passed as integer' do
        result = operation.create(name: 'Name', section_id: section.id, weight: 13)
        assert_predicate result, :success?
        assert_in_delta(13.0, result.value.weight)
      end

      it 'requires weight greater than 0' do
        result = operation.create(name: 'Name', section_id: section.id, weight: 0)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NOT_GT, result.error[:weight]
      end

      it 'requires weight greater than 0.0' do
        result = operation.create(name: 'Name', section_id: section.id, weight: 0.0)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NOT_GT, result.error[:weight]
      end

      it 'requires weight greater than something just below 0' do
        result = operation.create(name: 'Name', section_id: section.id, weight: -0.0001)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NOT_GT, result.error[:weight]
      end

      it 'requires weight just something above 0' do
        result = operation.create(
          { name: 'Name', section_id: section.id, weight: 0.0001 },
        )
        assert_predicate result, :success?
      end

      it 'converts blank description to nil' do
        sample = happy_operation.create(
          { name: 'Name1', section_id: section.id, description: '' },
        ).value
        assert_nil sample.description
      end
    end
  end

  describe '#update' do
    let(:existing_sample) do
      result = happy_operation.create(
        { name: 'Some Sample', weight: 1.1, description: 'abc', section_id: section.id },
      )
      assert_predicate result, :success?
      result.value
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      result = operation.update(id: existing_sample.id)
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, result.error[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Sample, existing_sample.id]

      result = operation.update(id: existing_sample.id)
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::UNAUTHORIZED, result.error[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Sample, existing_sample.id]
      end

      it 'does not require any attributs' do
        result = operation.update(id: existing_sample.id)
        assert_predicate result, :success?
      end

      it 'unsets blank weight and description attributes' do
        refute_nil existing_sample.weight
        refute_nil existing_sample.description

        result = operation.update(
          { id: existing_sample.id, weight: '', description: '' },
        )
        assert_predicate result, :success?
        sample = result.value
        assert_nil sample.weight
        assert_nil sample.description
      end

      it 'does not change section_id' do
        result = operation.update(
          { id: existing_sample.id, section_id: existing_sample.section_id + 1 },
        )
        assert_predicate result, :success?
        assert_equal existing_sample.section_id, result.value.section_id
      end

      it 'complains when name is nil' do
        result = operation.update(id: existing_sample.id, name: nil)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::BLANK, result.error[:name]
      end

      it 'complains when name is blank' do
        result = operation.update(id: existing_sample.id, name: '   ')
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::BLANK, result.error[:name]
      end

      it 'complains when name already exists' do
        result = happy_operation.create(
          { name: 'Some Other Name', section_id: section.id },
        )
        assert_predicate result, :success?

        result = operation.update(
          { id: existing_sample.id, name: 'Some Other Name' },
        )
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::TAKEN, result.error[:name]
      end

      it 'complains when name with different cases already exists' do
        result = happy_operation.create(
          { name: 'Some Other Name', section_id: section.id },
        )
        assert_predicate result, :success?

        result = operation.update(
          { id: existing_sample.id, name: '  some OTHER name  ' },
        )
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::TAKEN, result.error[:name]
      end

      it 'complains when name is too long' do
        max = 255
        result = operation.update(
          { id: existing_sample.id, name: 'a' * (max + 1) },
        )
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::TOO_LONG, result.error[:name]
      end

      it 'accepts max length name' do
        name = 'a' * 255
        result = operation.update(id: existing_sample.id, name: name)
        assert_predicate result, :success?
        assert_equal name, result.value.name
      end

      it 'requires numerical weight' do
        ['a', '#', '34a', 'a34'].each do |value|
          result = happy_operation.update(
            { id: existing_sample.id, weight: value },
          )
          assert_predicate result, :failure?
          assert_equal Paleolog::Operation::Params::NON_DECIMAL, result.error[:weight]
        end
      end

      it 'converts blank weight to nil' do
        result = happy_operation.update(
          { id: existing_sample.id, weight: ' ' },
        )
        assert_predicate result, :success?
        assert_nil result.value.weight
      end

      it 'requires weight greater than 0' do
        result = operation.update(
          { id: existing_sample.id, weight: 0 },
        )
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NOT_GT, result.error[:weight]
      end
    end
  end
end
