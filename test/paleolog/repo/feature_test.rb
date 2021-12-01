# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Feature do
  let(:repo) { Paleolog::Repo::Feature.new }

  after do
    repo.delete_all
  end

  describe '#all_for_species' do
    let(:group) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Group')) }
    let(:species) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Species', group: group)) }
    let(:other_species) { Paleolog::Repo.save(Paleolog::Species.new(name: 'Other Species', group: group)) }
    let(:field1) { Paleolog::Repo.save(Paleolog::Field.new(name: 'Field1', group: group)) }
    let(:field2) { Paleolog::Repo.save(Paleolog::Field.new(name: 'Field2', group: group)) }
    let(:choice11) { Paleolog::Repo.save(Paleolog::Choice.new(name: 'C11', field: field1)) }
    let(:choice12) { Paleolog::Repo.save(Paleolog::Choice.new(name: 'C12', field: field1)) }
    let(:choice21) { Paleolog::Repo.save(Paleolog::Choice.new(name: 'C21', field: field2)) }
    let(:choice22) { Paleolog::Repo.save(Paleolog::Choice.new(name: 'C22', field: field2)) }

    it 'returns all features defined for a species' do
      f1 = Paleolog::Repo.save(Paleolog::Feature.new(species: species, choice: choice11))
      f2 = Paleolog::Repo.save(Paleolog::Feature.new(species: species, choice: choice21))
      Paleolog::Repo.save(Paleolog::Feature.new(species: other_species, choice: choice12))

      result = repo.all_for_species(species.id)
      assert_equal([f1.id, f2.id], result.map(&:id))
    end

    it 'loads related choices' do
      Paleolog::Repo.save(Paleolog::Feature.new(species: species, choice: choice11))
      Paleolog::Repo.save(Paleolog::Feature.new(species: species, choice: choice21))

      result = repo.all_for_species(species.id)
      assert_equal([choice11.name, choice21.name], result.map { |feature| feature.choice.name })
    end
  end
end
