# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Feature do
  let(:repo) { Paleolog::Repo::Feature }

  after do
    repo.delete_all
  end

  describe '#all_for_species' do
    let(:group_id) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Group')) }
    let(:species_id) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Species', group_id: group_id)) }
    let(:other_species_id) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Other Species', group_id: group_id)) }
    let(:field1_id) { Paleolog::Repo.save(Paleolog::Field.new(name: 'Field1', group_id: group_id)) }
    let(:field2_id) { Paleolog::Repo.save(Paleolog::Field.new(name: 'Field2', group_id: group_id)) }
    let(:choice11) do
      Paleolog::Repo.find(
        Paleolog::Choice,
        Paleolog::Repo.save(Paleolog::Choice.new(name: 'C11', field_id: field1_id)),
      )
    end
    let(:choice12) do
      Paleolog::Repo.find(
        Paleolog::Choice,
        Paleolog::Repo.save(Paleolog::Choice.new(name: 'C12', field_id: field1_id)),
      )
    end
    let(:choice21) do
      Paleolog::Repo.find(
        Paleolog::Choice,
        Paleolog::Repo.save(Paleolog::Choice.new(name: 'C21', field_id: field2_id)),
      )
    end
    let(:choice22) do
      Paleolog::Repo.find(
        Paleolog::Choice,
        Paleolog::Repo.save(Paleolog::Choice.new(name: 'C22', field_id: field2_id)),
      )
    end

    it 'returns all features defined for a species' do
      f1_id = Paleolog::Repo.save(Paleolog::Feature.new(species_id: species_id, choice_id: choice11.id))
      f2_id = Paleolog::Repo.save(Paleolog::Feature.new(species_id: species_id, choice_id: choice21.id))
      Paleolog::Repo.save(Paleolog::Feature.new(species_id: other_species_id, choice_id: choice12.id))

      result = repo.all_for_species(species_id)
      assert_equal([f1_id, f2_id], result.map(&:id))
    end

    it 'loads related choices' do
      Paleolog::Repo.save(Paleolog::Feature.new(species_id: species_id, choice_id: choice11.id))
      Paleolog::Repo.save(Paleolog::Feature.new(species_id: species_id, choice_id: choice21.id))

      result = repo.all_for_species(species_id)
      assert_equal([choice11.name, choice21.name], result.map { |feature| feature.choice.name })
    end
  end
end
