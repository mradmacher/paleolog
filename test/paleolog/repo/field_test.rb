# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Field do
  let(:repo) { Paleolog::Repo::Field.new }

  after do
    repo.delete_all
  end

  describe '#all' do
    let(:group) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Group')) }

    before do
      repo.delete_all
    end

    it 'returns all fields' do
      field1 = Paleolog::Repo.save(Paleolog::Field.new(name: 'Field1', group: group))
      field2 = Paleolog::Repo.save(Paleolog::Field.new(name: 'Field2', group: group))
      result = repo.all
      assert_equal([field1, field2], result)
    end

    it 'loads all related choices' do
      field = Paleolog::Repo.save(Paleolog::Field.new(name: 'Field1', group: group))
      Paleolog::Repo.save(Paleolog::Choice.new(name: 'C1', field: field))
      Paleolog::Repo.save(Paleolog::Choice.new(name: 'C2', field: field))
      result = repo.all

      assert_equal(%w(C1 C2), result.first.choices.map(&:name))
    end
  end

  describe '#all_for' do
    let(:group) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Group')) }

    it 'returns all fields for given ids' do
      field1 = Paleolog::Repo.save(Paleolog::Field.new(name: 'Field1', group: group))
      field2 = Paleolog::Repo.save(Paleolog::Field.new(name: 'Field2', group: group))
      result = repo.all_for([field1.id])
      assert_equal([field1], result)
    end
  end
end
