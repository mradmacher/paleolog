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
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert result.success?
      refute_nil result.value.id
      refute_nil Paleolog::Repo::Occurrence.find(result.value.id)
    end

    it 'assigns new rank' do
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert result.success?
      assert_equal 1, result.value.rank
    end

    it 'assigns rank greater than already existing' do
      other_species = Paleolog::Repo.save(Paleolog::Species.new(group: group, name: 'Other species'))
      result = operation.create(sample_id: sample.id, species_id: other_species.id, counting_id: counting.id)
      assert result.success?
      assert_equal 1, result.value.rank

      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert result.success?
      assert_equal 2, result.value.rank
    end

    it 'assigns normal status' do
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert result.success?
      assert_equal Paleolog::CountingSummary::NORMAL, result.value.status
    end

    it 'requires counting, sample and species id' do
      result = operation.create(counting_id: nil, species_id: nil, sample_id: nil)
      assert result.failure?
      assert(result.error[:counting_id].include?('must be filled'))
      assert(result.error[:sample_id].include?('must be filled'))
      assert(result.error[:species_id].include?('must be filled'))
    end

    it 'ensures counting and sample are from same project' do
      other_project = Paleolog::Repo.save(Paleolog::Project.new(name: 'Some Other Project'))
      other_counting = Paleolog::Repo.save(
        Paleolog::Counting.new(name: 'Some Other Counting', project: other_project)
      )
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: other_counting.id)
      assert result.failure?
      assert(result.error[:counting_id].include?('must be filled'))
    end

    it 'does not allow same species within a counting and sample' do
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert result.success?
      result = operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id)
      assert result.failure?
      assert(result.error[:species_id].include?('is already taken'))
    end
  end

  describe '#update' do
    let(:occurrence) { operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id).value }

    it 'accepts valid statuses' do
      [
        Paleolog::CountingSummary::NORMAL,
        Paleolog::CountingSummary::OUTSIDE_COUNT,
        Paleolog::CountingSummary::CARVING,
        Paleolog::CountingSummary::REWORKING
      ].each do |value|
        result = operation.update(occurrence.id, status: value)
        assert result.success?
        assert_equal value, result.value.status
      end
    end

    it 'refutes invalid statuses' do
      [-100, -1, 4, 5, 100].each do |value|
        result = operation.update(occurrence.id, status: value)
        assert result.failure?
        assert result.error[:status].include?('must be one of: 0, 1, 2, 3')
      end
    end

    it 'accepts uncertain flag' do
      result = operation.update(occurrence.id, uncertain: true)
      assert result.success?
      assert_equal true, result.value.uncertain

      result = operation.update(occurrence.id, uncertain: '1')
      assert result.success?
      assert_equal true, result.value.uncertain

      result = operation.update(occurrence.id, uncertain: false)
      assert result.success?
      assert_equal false, result.value.uncertain

      result = operation.update(occurrence.id, uncertain: '0')
      assert result.success?
      assert_equal false, result.value.uncertain
    end

    it 'accepts possitive quantity' do
      result = operation.update(occurrence.id, quantity: 1)
      assert result.success?
      assert_equal 1, result.value.quantity
    end

    it 'accepts 0 quantity' do
      result = operation.update(occurrence.id, quantity: 0)
      assert result.success?
      assert_equal 0, result.value.quantity
    end

    it 'accepts nil quantity' do
      result = operation.update(occurrence.id, quantity: nil)
      assert result.success?
      assert_nil result.value.quantity
    end

    it 'rejects negative quantity' do
      result = operation.update(occurrence.id, quantity: -1)
      assert result.failure?
      assert result.error[:quantity].include?('must be greater than or equal to 0')
    end

    it 'accepts integer quantity passed as string' do
      result = operation.update(occurrence.id, quantity: '1')
      assert result.success?
      assert_equal 1, result.value.quantity
    end

    it 'rejects string quantity' do
      result = operation.update(occurrence.id, quantity: 'five')
      assert result.failure?
      assert result.error[:quantity].include?('must be an integer')
    end

    it 'rejects double quantity' do
      result = operation.update(occurrence.id, quantity: '1.1')
      assert result.failure?
      assert result.error[:quantity].include?('must be an integer')
    end
  end

  describe '#shift' do

  end
end
