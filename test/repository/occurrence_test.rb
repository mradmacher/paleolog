# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repository::Occurrence do
  let(:authorizer) { Minitest::Mock.new }
  let(:operation) do
    Paleolog::Repository::Occurrence.new(Paleolog.db, authorizer)
  end
  let(:happy_operation) do
    happy_operation_for(Paleolog::Repository::Occurrence, user)
  end
  let(:user) do
    Paleolog::Repository::User.new(Paleolog.db, nil).create(login: 'test', password: 'test123').value
  end
  let(:project) do
    happy_operation_for(Paleolog::Repository::Project, user)
      .create(name: 'some project')
      .value
  end
  let(:counting) do
    happy_operation_for(Paleolog::Repository::Counting, user)
      .create(name: 'some counting', project_id: project.id)
      .value
  end
  let(:section) do
    happy_operation_for(Paleolog::Repository::Section, user)
      .create(name: 'some section', project_id: project.id)
      .value
  end
  let(:sample) do
    happy_operation_for(Paleolog::Repository::Sample, user)
      .create(name: 'some sample', section_id: section.id)
      .value
  end
  let(:group) do
    happy_operation_for(Paleolog::Repository::Group, user)
      .create(name: 'Dinoflagellate')
      .value
  end
  let(:species) do
    happy_operation_for(Paleolog::Repository::Species, user)
      .create(group_id: group.id, name: 'Odontochitina costata')
      .value
  end

  describe '#all' do
    it 'returns all occurrences for given sample and counting' do
      other_counting = happy_operation_for(Paleolog::Repository::Counting, user)
                       .create(name: 'Other counting', project_id: project.id).value
      other_sample = happy_operation_for(Paleolog::Repository::Sample, user)
                     .create(name: 'Other sample', section_id: section.id).value
      other_species = happy_operation_for(Paleolog::Repository::Species, user)
                      .create(name: 'Other species', group_id: group.id).value

      occurrence1 = operation.create(
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample.id,
      ).value
      operation.create(
        species_id: species.id,
        counting_id: counting.id,
        sample_id: other_sample.id,
      )
      operation.create(
        species_id: species.id,
        counting_id: other_counting.id,
        sample_id: sample.id,
      )
      occurrence4 = operation.create(
        species_id: other_species.id,
        counting_id: counting.id,
        sample_id: sample.id,
      ).value
      operation.create(
        species_id: other_species.id,
        counting_id: other_counting.id,
        sample_id: sample.id,
      )
      operation.create(
        species_id: other_species.id,
        counting_id: counting.id,
        sample_id: other_sample.id,
      )

      operation.find_all(counting_id: counting.id, sample_id: sample.id)
               .on_failure { |error| flunk "Expected success, got #{error}" }
               .on_success do |result|
        assert_equal [occurrence1.id, occurrence4.id].sort, result.map(&:id).sort
      end
    end

    it 'returns all occurrences for given section and counting' do
      sample1 = happy_operation_for(Paleolog::Repository::Sample, user)
                .create(name: 'Sample1', section_id: section.id)
                .value
      sample2 = happy_operation_for(Paleolog::Repository::Sample, user)
                .create(name: 'Sample2', section_id: section.id)
                .value

      other_counting = happy_operation_for(Paleolog::Repository::Counting, user)
                       .create(name: 'Other counting', project_id: project.id)
                       .value
      other_section = happy_operation_for(Paleolog::Repository::Section, user)
                      .create(name: 'Other section', project_id: project.id)
                      .value
      other_sample = happy_operation_for(Paleolog::Repository::Sample, user)
                     .create(name: 'Other sample', section_id: other_section.id)
                     .value

      occurrence1 = operation.create(
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample1.id,
      ).value
      occurrence2 = operation.create(
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample2.id,
      ).value
      operation.create(
        species_id: species.id,
        counting_id: counting.id,
        sample_id: other_sample.id,
      )
      operation.create(
        species_id: species.id,
        counting_id: other_counting.id,
        sample_id: sample1.id,
      )

      operation.find_all(counting_id: counting.id, section_id: section.id)
               .on_failure { |error| flunk "Expected success, got #{error}" }
               .on_success do |result|
        assert_equal [occurrence1.id, occurrence2.id].sort, result.map(&:id).sort
      end
    end

    it 'loads species with groups' do
      occurrence = operation.create(
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample.id,
      ).value
      operation.find_all(counting_id: counting.id, sample_id: sample.id)
               .on_failure { |error| flunk "Expected success, got #{error}" }
               .on_success do |occurrences|
        occurrence = occurrences.first

        refute_nil occurrence.species
        refute_nil occurrence.species.group
      end
    end

    it 'loads sample' do
      occurrence = operation.create(
        species_id: species.id,
        counting_id: counting.id,
        sample_id: sample.id,
      ).value
      operation.find_all(counting_id: counting.id, sample_id: sample.id)
               .on_failure { |error| flunk "Expected success, got #{error}" }
               .on_success do |occurrences|
        occurrence = occurrences.first

        refute_nil occurrence.sample
      end
    end
  end

  describe '#find' do
    let(:occurrence) do
      operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id).value
    end

    it 'requires authenticated user' do
      authorizer.expect :authenticated?, false

      operation.find(id: occurrence.id)
               .on_success { |value| flunk "Expected error, got #{value}" }
               .on_failure { |error| assert Paleolog::Operation.unauthenticated?(error) }

      authorizer.verify
    end

    describe 'for authenticated user' do
      before do
        authorizer.expect :authenticated?, true
      end

      it 'returns occurrence' do
        operation.find(id: occurrence.id)
                 .on_failure { |error| flunk "Expected success, got #{error}" }
                 .on_success do |found_occurrence|
          refute_nil found_occurrence

          refute_nil found_occurrence.id
          assert_equal found_occurrence.id, occurrence.id
          assert_equal found_occurrence.species_id, occurrence.species_id
          assert_equal found_occurrence.counting_id, occurrence.counting_id
          assert_equal found_occurrence.sample_id, occurrence.sample_id
        end
      end

      it 'returns existing occurrence for given project' do
        authorizer.expect :can_view?, true, [Paleolog::Occurrence, occurrence.id]

        operation.find(id: occurrence.id, project_id: project.id)
                 .on_success do |found_occurrence|
          refute_nil found_occurrence
          assert_equal occurrence.id, found_occurrence.id
        end.on_failure do |error|
          flunk("Expected occurrence but got #{error}")
        end
      end

      it 'fails for existing counting but different given project' do
        authorizer.expect :can_view?, true, [Paleolog::Occurrence, occurrence.id]

        operation.find(id: counting.id, project_id: project.id + 1)
                 .on_failure do |error|
          assert Paleolog::Operation.not_found?(error), "Expected not found error, got #{error}"
        end.on_success do |found_occurrence|
          flunk("Expected error, got occurrence #{found_occurrence}")
        end
      end
    end
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
      other_species = happy_operation_for(Paleolog::Repository::Species, user)
                      .create(group_id: group.id, name: 'Other species')
                      .value
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
      assert_equal Paleolog::Repository::Params::NON_INTEGER, result.error[:counting_id]
      assert_equal Paleolog::Repository::Params::NON_INTEGER, result.error[:sample_id]
      assert_equal Paleolog::Repository::Params::NON_INTEGER, result.error[:species_id]
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
        assert_equal Paleolog::Repository::Params::NOT_INCLUDED, result.error[:status]
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
      assert_equal Paleolog::Repository::Params::NOT_GTE, result.error[:quantity]
    end

    it 'accepts integer quantity passed as string' do
      result = operation.update(id: occurrence.id, quantity: '1')

      assert_predicate result, :success?
      assert_equal 1, result.value.quantity
    end

    it 'rejects string quantity' do
      result = operation.update(id: occurrence.id, quantity: 'five')

      assert_predicate result, :failure?
      assert_equal Paleolog::Repository::Params::NON_INTEGER, result.error[:quantity]
    end

    it 'rejects double quantity' do
      result = operation.update(id: occurrence.id, quantity: '1.1')

      assert_predicate result, :failure?
      assert_equal Paleolog::Repository::Params::NON_INTEGER, result.error[:quantity]
    end
  end

  describe '#delete' do
    let(:occurrence) do
      operation.create(sample_id: sample.id, species_id: species.id, counting_id: counting.id).value
    end

    it 'requires id' do
      operation.delete({})
               .on_success { |value| flunk "Expected error, got #{value}" }
               .on_failure { |error| assert_equal Paleolog::Repository::Params::MISSING, error[:id] }
    end

    it 'removes occurrence' do
      operation.delete(id: occurrence.id)
               .on_failure { |error| flunk "Expected success, got #{error}" }
               .on_success do
        happy_operation.find(id: occurrence.id)
                       .on_success { |occurrence| flunk "Expected no occurrence, found #{occurrence}" }
                       .on_failure { |error| assert Paleolog::Operation.not_found?(error) }
      end
    end
  end
end
