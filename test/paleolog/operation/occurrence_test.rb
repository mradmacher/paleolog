# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Operation::Occurrence do
  let(:operation) { Paleolog::Operation::Occurrence }

  let(:project) { Paleolog::Repo.save(Paleolog::Project.new(name: 'some project')) }
  let(:counting) { Paleolog::Repo.save(Paleolog::Counting.new(name: 'some counting', project: project)) }
  let(:section) { Paleolog::Repo.save(Paleolog::Section.new(name: 'some section', project: project)) }
  let(:sample) { Paleolog::Repo.save(Paleolog::Sample.new(name: 'some sample', section: section)) }
  let(:group) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Dinoflagellate')) }
  let(:species) { Paleolog::Repo.save(Paleolog::Species.new(group: group, name: 'Odontochitina costata')) }

  describe '#create' do
    it 'creates new occurrence' do
      occurrence, errors = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate errors, :empty?
      refute_nil occurrence.id
      refute_nil Paleolog::Repo::Occurrence.find(occurrence.id)
    end

    it 'assigns new rank' do
      occurrence, errors = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate errors, :empty?
      assert_equal 1, occurrence.rank
    end

    it 'assigns rank greater than already existing' do
      other_species = Paleolog::Repo.save(Paleolog::Species.new(group: group, name: 'Other species'))
      occurrence, errors = operation.create(
        sample_id: sample.id,
        species_id: other_species.id,
        counting_id: counting.id,
      )
      assert_predicate errors, :empty?
      assert_equal 1, occurrence.rank

      occurrence, errors = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate errors, :empty?
      assert_equal 2, occurrence.rank
    end

    it 'assigns normal status' do
      occurrence, errors = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate errors, :empty?
      assert_equal Paleolog::Occurrence::NORMAL, occurrence.status
    end

    it 'requires counting, sample and species id' do
      _, errors = operation.create(counting_id: nil, species_id: nil, sample_id: nil)
      refute_predicate errors, :empty?
      assert_equal ParamParam::NON_INTEGER, errors[:counting_id]
      assert_equal ParamParam::NON_INTEGER, errors[:sample_id]
      assert_equal ParamParam::NON_INTEGER, errors[:species_id]
    end

    it 'ensures counting and sample are from same project' do
      other_project = Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Other Project'))
      other_counting = Paleolog::Repo.save(
        Paleolog::Counting.new(name: 'Some Other Counting', project: other_project),
      )
      _, errors = operation.create(sample_id: sample.id, species_id: species.id, counting_id: other_counting.id)
      refute_predicate errors, :empty?
      raise 'decide on errors value'
    end

    it 'does not allow same species within a counting and sample' do
      _, errors = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert_predicate errors, :empty?
      _, errors = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      refute_predicate errors, :empty?
      assert_equal :taken, errors[:species_id]
    end
  end

  describe '#update' do
    let(:occurrence) { operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id).first }

    it 'accepts valid statuses' do
      Paleolog::Occurrence::STATUSES.each do |value|
        updated, errors = operation.update(occurrence.id, status: value)
        assert_predicate errors, :empty?
        assert_equal value, updated.status
      end
    end

    it 'refutes invalid statuses' do
      [-100, -1, 4, 5, 100].each do |value|
        _, errors = operation.update(occurrence.id, status: value)
        refute_predicate errors, :empty?
        assert_equal ParamParam::NOT_INCLUDED, errors[:status]
      end
    end

    it 'accepts uncertain flag' do
      updated, errors = operation.update(occurrence.id, uncertain: true)
      assert_predicate errors, :empty?
      assert updated.uncertain

      updated, errors = operation.update(occurrence.id, uncertain: '1')
      assert_predicate errors, :empty?
      assert updated.uncertain

      updated, errors = operation.update(occurrence.id, uncertain: false)
      assert_predicate errors, :empty?
      refute updated.uncertain

      updated, errors = operation.update(occurrence.id, uncertain: '0')
      assert_predicate errors, :empty?
      refute updated.uncertain
    end

    it 'accepts possitive quantity' do
      updated, errors = operation.update(occurrence.id, quantity: 1)
      assert_predicate errors, :empty?
      assert_equal 1, updated.quantity
    end

    it 'accepts 0 quantity' do
      updated, errors = operation.update(occurrence.id, quantity: 0)
      assert_predicate errors, :empty?
      assert_equal 0, updated.quantity
    end

    it 'accepts nil quantity' do
      updated, errors = operation.update(occurrence.id, quantity: nil)
      assert_predicate errors, :empty?
      assert_nil updated.quantity
    end

    it 'rejects negative quantity' do
      _, errors = operation.update(occurrence.id, quantity: -1)
      refute_predicate errors, :empty?
      assert_equal ParamParam::NOT_GTE, errors[:quantity]
    end

    it 'accepts integer quantity passed as string' do
      updated, errors = operation.update(occurrence.id, quantity: '1')
      assert_predicate errors, :empty?
      assert_equal 1, updated.quantity
    end

    it 'rejects string quantity' do
      _, errors = operation.update(occurrence.id, quantity: 'five')
      refute_predicate errors, :empty?
      assert_equal ParamParam::NON_INTEGER, errors[:quantity]
    end

    it 'rejects double quantity' do
      _, errors = operation.update(occurrence.id, quantity: '1.1')
      refute_predicate errors, :empty?
      assert_equal ParamParam::NON_INTEGER, errors[:quantity]
    end
  end
end
