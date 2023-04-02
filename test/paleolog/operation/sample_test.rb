# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Sample do
  let(:operation) { Paleolog::Operation::Sample }
  let(:user) { Paleolog::Repo.save(Paleolog::User.new(login: 'test', password: 'test123')) }
  let(:project) do
    Paleolog::Operation::Project.create(
      { name: 'Project for Section', user_id: user.id },
      authorizer: HappyAuthorizer.new,
    ).first
  end
  let(:section) do
    Paleolog::Operation::Section.create(
      { name: 'Section for Sample', project_id: project.id },
      authorizer: HappyAuthorizer.new,
    ).first
  end
  let(:authorizer) { Minitest::Mock.new }

  after do
    Paleolog::Repo::Sample.delete_all
    Paleolog::Repo::Section.delete_all
    Paleolog::Repo::Researcher.delete_all
    Paleolog::Repo::Project.delete_all
  end

  describe '#create' do
    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      _, errors = operation.create({ name: 'Some Name', section_id: section.id }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, errors[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Section, section.id]

      _, errors = operation.create({ name: 'Some Name', section_id: section.id }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Section, section.id]
      end

      it 'increases rank for each new sample' do
        sample, = operation.create(
          { name: 'Name1', section_id: section.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_equal 1, sample.rank

        sample, = operation.create(
          { name: 'Name2', section_id: section.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_equal 2, sample.rank

        sample, = operation.create(
          { name: 'Name3', section_id: section.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_equal 3, sample.rank
      end

      it 'increases rank in the scope of a section' do
        other_section, = Paleolog::Operation::Section.create(
          { name: 'Other Section for Sample', project_id: project.id },
          authorizer: HappyAuthorizer.new,
        )

        sample, = operation.create(
          { name: 'Name1', section_id: section.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_equal 1, sample.rank

        sample, = operation.create(
          { name: 'Name2', section_id: other_section.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_equal 1, sample.rank
      end

      it 'complains when section_id nil' do
        _, errors = operation.create({ name: 'Name', section_id: nil }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::NON_INTEGER, errors[:section_id]
      end

      it 'complains when section_id missing' do
        _, errors = operation.create({ name: 'Name' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::MISSING, errors[:section_id]
      end

      it 'complains when name is nil' do
        _, errors = operation.create({ name: nil, section_id: section.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::BLANK, errors[:name]
      end

      it 'complains when name is blank' do
        _, errors = operation.create({ name: '  ', section_id: section.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::BLANK, errors[:name]
      end

      it 'complains when name is missing' do
        _, errors = operation.create({ section_id: section.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::MISSING, errors[:name]
      end

      it 'complains when name already exists' do
        _, errors = operation.create({ name: 'Some Name', section_id: section.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.create({ name: 'Some Name', section_id: section.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::TAKEN, errors[:name]
      end

      it 'complains when name with different cases already exists' do
        _, errors = operation.create({ name: 'Some Name', section_id: section.id }, authorizer: HappyAuthorizer.new)
        assert_predicate errors, :empty?

        _, errors = operation.create({ name: ' some name ', section_id: section.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::TAKEN, errors[:name]
      end

      it 'complains when name is too long' do
        max = 255
        _, errors = operation.create({ name: 'a' * (max + 1), section_id: section.id }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::TOO_LONG, errors[:name]
      end

      it 'accepts max length name' do
        max = 255
        _, errors = operation.create({ name: 'a' * max, section_id: section.id }, authorizer: authorizer)
        assert_predicate errors, :empty?
      end

      it 'requires numerical weight' do
        ['  ', 'a', '#', '34a', 'a34'].each do |value|
          _, errors = operation.create(
            { name: 'Name', section_id: section.id, weight: value },
            authorizer: HappyAuthorizer.new,
          )
          refute_predicate errors, :empty?
          assert_equal Paleolog::Operation::NON_DECIMAL, errors[:weight]
        end
      end

      it 'accepts weight passed as string' do
        sample, errors = operation.create(
          { name: 'Name', section_id: section.id, weight: '1.3' },
          authorizer: authorizer,
        )
        assert_predicate errors, :empty?
        assert_in_delta(1.3, sample.weight)
      end

      it 'accepts weight passed as decimal' do
        sample, errors = operation.create(
          { name: 'Name', section_id: section.id, weight: 1.3 },
          authorizer: authorizer,
        )
        assert_predicate errors, :empty?
        assert_in_delta(1.3, sample.weight)
      end

      it 'accepts weight passed as integer' do
        sample, errors = operation.create(
          { name: 'Name', section_id: section.id, weight: 13 },
          authorizer: authorizer,
        )
        assert_predicate errors, :empty?
        assert_in_delta(13.0, sample.weight)
      end

      it 'requires weight greater than 0' do
        _, errors = operation.create({ name: 'Name', section_id: section.id, weight: 0 }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::NOT_GT, errors[:weight]
      end

      it 'requires weight greater than 0.0' do
        _, errors = operation.create({ name: 'Name', section_id: section.id, weight: 0.0 }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::NOT_GT, errors[:weight]
      end

      it 'requires weight greater than something just below 0' do
        _, errors = operation.create({ name: 'Name', section_id: section.id, weight: -0.0001 }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::NOT_GT, errors[:weight]
      end

      it 'requires weight just something above 0' do
        _, errors = operation.create({ name: 'Name', section_id: section.id, weight: 0.0001 }, authorizer: authorizer)
        assert_predicate errors, :empty?
      end
    end
  end

  describe '#update' do
    let(:existing_sample) do
      sample, errors = operation.create(
        { name: 'Some Sample', weight: 1.1, description: 'abc', section_id: section.id },
        authorizer: HappyAuthorizer.new,
      )
      assert_predicate errors, :empty?
      sample
    end

    it 'returns unauthenticated error when not authenticated' do
      authorizer.expect :authenticated?, false

      _, errors = operation.update({ id: existing_sample.id }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHENTICATED, errors[:general]

      authorizer.verify
    end

    it 'returns unauthorized error when not authorized' do
      authorizer.expect :authenticated?, true
      authorizer.expect :can_manage?, false, [Paleolog::Sample, existing_sample.id]

      _, errors = operation.update({ id: existing_sample.id }, authorizer: authorizer)
      refute_predicate errors, :empty?
      assert_equal Paleolog::Operation::UNAUTHORIZED, errors[:general]

      authorizer.verify
    end

    describe 'for authorized user' do
      before do
        authorizer.expect :authenticated?, true
        authorizer.expect :can_manage?, true, [Paleolog::Sample, existing_sample.id]
      end

      it 'does not require any attributs' do
        _, errors = operation.update({ id: existing_sample.id }, authorizer: authorizer)
        assert_predicate errors, :empty?
      end

      it 'unsets blank weight and description attributes' do
        refute_nil existing_sample.weight
        refute_nil existing_sample.description

        sample, errors = operation.update(
          { id: existing_sample.id, weight: '', description: '' },
          authorizer: authorizer,
        )
        assert_predicate errors, :empty?
        assert_nil sample.weight
        assert_nil sample.description
      end

      it 'does not change section_id' do
        sample, errors = operation.update(
          { id: existing_sample.id, section_id: existing_sample.section_id + 1 },
          authorizer: authorizer,
        )
        assert_predicate errors, :empty?
        assert_equal existing_sample.section_id, sample.section_id
      end

      it 'complains when name is nil' do
        _, errors = operation.update({ id: existing_sample.id, name: nil }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::BLANK, errors[:name]
      end

      it 'complains when name is blank' do
        _, errors = operation.update({ id: existing_sample.id, name: '   ' }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::BLANK, errors[:name]
      end

      it 'complains when name already exists' do
        _, errors = operation.create(
          { name: 'Some Other Name', section_id: section.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_predicate errors, :empty?

        _, errors = operation.update(
          { id: existing_sample.id, name: 'Some Other Name' },
          authorizer: authorizer,
        )
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::TAKEN, errors[:name]
      end

      it 'complains when name with different cases already exists' do
        _, errors = operation.create(
          { name: 'Some Other Name', section_id: section.id },
          authorizer: HappyAuthorizer.new,
        )
        assert_predicate errors, :empty?

        _, errors = operation.update(
          { id: existing_sample.id, name: '  some OTHER name  ' },
          authorizer: authorizer,
        )
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::TAKEN, errors[:name]
      end

      it 'complains when name is too long' do
        max = 255
        _, errors = operation.update({ id: existing_sample.id, name: 'a' * (max + 1) }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::TOO_LONG, errors[:name]
      end

      it 'accepts max length name' do
        max = 255
        _, errors = operation.update({ id: existing_sample.id, name: 'a' * max }, authorizer: authorizer)
        assert_predicate errors, :empty?
      end

      it 'requires numerical weight' do
        ['  ', 'a', '#', '34a', 'a34'].each do |value|
          _, errors = operation.create({ id: existing_sample.id, weight: value }, authorizer: HappyAuthorizer.new)
          refute_predicate errors, :empty?
          assert_equal Paleolog::Operation::NON_DECIMAL, errors[:weight]
        end
      end

      it 'requires weight greater than 0' do
        _, errors = operation.update({ id: existing_sample.id, weight: 0 }, authorizer: authorizer)
        refute_predicate errors, :empty?
        assert_equal Paleolog::Operation::NOT_GT, errors[:weight]
      end
    end
  end
end
