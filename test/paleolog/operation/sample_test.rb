# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Sample do
  let(:operation) { Paleolog::Operation::Sample }
  let(:project) { Paleolog::Operation::Project.create(name: 'Project for Section').value }
  let(:section) { Paleolog::Operation::Section.create(name: 'Section for Sample', project_id: project.id).value }

  after do
    Paleolog::Repo::Sample.delete_all
    Paleolog::Repo::Section.delete_all
    Paleolog::Repo::Project.delete_all
  end

  describe '#create' do
    it 'does not complain when name not taken yet' do
      result = operation.create(name: 'Some Name', section_id: section.id)
      assert result.success?

      result = operation.create(name: 'Other Name', section_id: section.id)
      assert result.success?
    end

    it 'complains when section_id blank' do
      result = operation.create(name: 'Name', section_id: nil)
      assert result.failure?
      assert_equal :noninteger, result.error[:section_id]

      result = operation.create(name: 'Name', section_id: Option.None)
      assert result.failure?
      assert_equal :missing, result.error[:section_id]
    end

    it 'complains when name is blank' do
      result = operation.create(name: nil, section_id: section.id)
      assert result.failure?
      assert_equal :blank, result.error[:name]

      result = operation.create(name: '  ', section_id: section.id)
      assert result.failure?
      assert_equal :blank, result.error[:name]
    end

    it 'complains when name already exists' do
      result = operation.create(name: 'Some Name', section_id: section.id)
      assert result.success?

      result = operation.create(name: 'Some Name', section_id: section.id)
      assert result.failure?
      assert_equal :taken, result.error[:name]
    end

    it 'complains when name is too long' do
      max = 255
      result = operation.create(name: 'a' * (max + 1), section_id: section.id)
      assert result.failure?
      assert_equal :too_long, result.error[:name]

      result = operation.create(name: 'a' * max, section_id: section.id)
      assert result.success?
    end

    it 'complains when name with different cases already exists' do
      result = operation.create(name: 'Some Name', section_id: section.id)
      assert result.success?

      result = operation.create(name: ' some name ', section_id: section.id)
      assert result.failure?
      assert_equal :taken, result.error[:name]
    end

    it 'requires numerical weight' do
      ['  ', 'a', '#', '34a', 'a34'].each do |value|
        result = operation.create(name: 'Name', section_id: section.id, weight: value)
        assert result.failure?
        assert :nondecimal, result.error[:weight]
      end
    end

    it 'accepts weight passed as string' do
      result = operation.create(name: 'Name', section_id: section.id, weight: '1.3')
      assert result.success?
      assert 1.3, result.value.weight
    end

    it 'accepts weight passed as decimal' do
      result = operation.create(name: 'Name', section_id: section.id, weight: 1.3)
      assert result.success?
      assert 1.3, result.value.weight
    end

    it 'accepts weight passed as integer' do
      result = operation.create(name: 'Name', section_id: section.id, weight: 13)
      assert result.success?
      assert 13.0, result.value.weight
    end

    it 'requires weight greater than 0 when present' do
      result = operation.create(name: 'Name', section_id: section.id, weight: 0)
      assert result.failure?
      assert :gt, result.error[:weight]

      result = operation.create(name: 'Name', section_id: section.id, weight: 0.0)
      assert result.failure?
      assert :gt, result.error[:weight]

      result = operation.create(name: 'Name', section_id: section.id, weight: -0.1)
      assert result.failure?
      assert :gt, result.error[:weight]

      result = operation.create(name: 'Name', section_id: section.id, weight: 0.0001)
      assert result.success?
    end
  end
end
