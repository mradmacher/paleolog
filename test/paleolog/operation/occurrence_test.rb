# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Occurrence do
  let(:repo) { Paleolog::Repo }
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) do
    Paleolog::Operation::Occurrence.new(repo, authorizer)
  end
  let(:user) do
    id = repo.save(Paleolog::User.new(login: 'test', password: 'test123'))
    repo.find(Paleolog::User, id)
  end
  let(:project) do
    happy_operation_for(Paleolog::Operation::Project, user)
      .create(name: 'some project')
      .value
  end
  let(:counting) do
    happy_operation_for(Paleolog::Operation::Counting, user)
      .create(name: 'some counting', project_id: project.id)
      .value
  end
  let(:section) do
    happy_operation_for(Paleolog::Operation::Section, user)
      .create(name: 'some section', project_id: project.id)
      .value
  end
  let(:sample) do
    happy_operation_for(Paleolog::Operation::Sample, user)
      .create(name: 'some sample', section_id: section.id)
      .value
  end
  let(:group) do
    happy_operation_for(Paleolog::Operation::Group, user)
      .create(name: 'Dinoflagellate')
      .value
  end
  let(:species) do
    happy_operation_for(Paleolog::Operation::Species, user)
      .create(group_id: group.id, name: 'Odontochitina costata')
      .value
  end

  after do
    repo.for(Paleolog::Sample).delete_all
    repo.for(Paleolog::Section).delete_all
    repo.for(Paleolog::Counting).delete_all
    repo.for(Paleolog::Researcher).delete_all
    repo.for(Paleolog::Project).delete_all
    repo.for(Paleolog::User).delete_all
    repo.for(Paleolog::Species).delete_all
    repo.for(Paleolog::Group).delete_all
  end

  describe '#create' do
    it 'creates new occurrence' do
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate result, :success?

      occurrence = result.value
      refute_nil occurrence
      refute_nil occurrence.id
    end

    it 'assigns new rank' do
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate result, :success?
      assert_equal 1, result.value.rank
    end

    it 'assigns rank greater than already existing' do
      other_species = happy_operation_for(Paleolog::Operation::Species, user).create(group_id: group.id, name: 'Other species').value
      result = operation.create(
        sample_id: sample.id,
        species_id: other_species.id,
        counting_id: counting.id,
      )
      assert_predicate result, :success?
      assert_equal 1, result.value.rank

      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate result, :success?
      assert_equal 2, result.value.rank
    end

    it 'assigns normal status' do
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate result, :success?
      assert_equal Paleolog::Occurrence::NORMAL, result.value.status
    end

    it 'requires counting, sample and species id' do
      result = operation.create(counting_id: nil, species_id: nil, sample_id: nil)
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:counting_id]
      assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:sample_id]
      assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:species_id]
    end

    # it 'ensures counting and sample are from same project' do
    #   other_project = Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Other Project'))
    #   other_counting = Paleolog::Repo.save(
    #     Paleolog::Counting.new(name: 'Some Other Counting', project: other_project),
    #   )
    #   _, errors = operation.create(sample_id: sample.id, species_id: species.id, counting_id: other_counting.id)
    #   refute_predicate errors, :empty?
    #   raise 'decide on errors value'
    # end

    it 'does not allow same species within a counting and sample' do
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate result, :success?
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate result, :failure?
      assert_equal :taken, result.error[:species_id]
    end
  end

  describe '#update' do
    let(:occurrence) do
      operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id).value
    end

    it 'accepts valid statuses' do
      Paleolog::Occurrence::STATUSES.each do |value|
        result = operation.update(id: occurrence.id, status: value)
        assert_predicate result, :success?
        assert_equal value, result.value.status
      end
    end

    it 'refutes invalid statuses' do
      [-100, -1, 4, 5, 100].each do |value|
        result = operation.update(id: occurrence.id, status: value)
        assert_predicate result, :failure?
        assert_equal Paleolog::Operation::Params::NOT_INCLUDED, result.error[:status]
      end
    end

    it 'accepts uncertain flag' do
      result = operation.update(id: occurrence.id, uncertain: true)
      assert_predicate result, :success?
      assert result.value.uncertain

      result = operation.update(id: occurrence.id, uncertain: '1')
      assert_predicate result, :success?
      assert result.value.uncertain

      result = operation.update(id: occurrence.id, uncertain: false)
      assert_predicate result, :success?
      refute result.value.uncertain

      result = operation.update(id: occurrence.id, uncertain: '0')
      assert_predicate result, :success?
      refute result.value.uncertain
    end

    it 'accepts possitive quantity' do
      result = operation.update(id: occurrence.id, quantity: 1)
      assert_predicate result, :success?
      assert_equal 1, result.value.quantity
    end

    it 'accepts 0 quantity' do
      result = operation.update(id: occurrence.id, quantity: 0)
      assert_predicate result, :success?
      assert_equal 0, result.value.quantity
    end

    it 'accepts nil quantity' do
      result = operation.update(id: occurrence.id, quantity: nil)
      assert_predicate result, :success?
      assert_nil result.value.quantity
    end

    it 'rejects negative quantity' do
      result = operation.update(id: occurrence.id, quantity: -1)
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::Params::NOT_GTE, result.error[:quantity]
    end

    it 'accepts integer quantity passed as string' do
      result = operation.update(id: occurrence.id, quantity: '1')
      assert_predicate result, :success?
      assert_equal 1, result.value.quantity
    end

    it 'rejects string quantity' do
      result = operation.update(id: occurrence.id, quantity: 'five')
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:quantity]
    end

    it 'rejects double quantity' do
      result = operation.update(id: occurrence.id, quantity: '1.1')
      assert_predicate result, :failure?
      assert_equal Paleolog::Operation::Params::NON_INTEGER, result.error[:quantity]
    end
  end
end
