# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Field do
  let(:repo) { Paleolog::Repo::Field }
  let(:group_id) { Paleolog::Repo.save(Paleolog::Group.new(name: 'Group')) }

  after do
    repo.delete_all
  end

  describe '#all' do
    it 'returns all fields' do
      field1_id = Paleolog::Repo.save(Paleolog::Field.new(name: 'Field1', group_id: group_id))
      field2_id = Paleolog::Repo.save(Paleolog::Field.new(name: 'Field2', group_id: group_id))
      result = repo.all

      assert_equal([field1_id, field2_id], result.map(&:id))
    end

    it 'loads all related choices' do
      field_id = Paleolog::Repo.save(Paleolog::Field.new(name: 'Field1', group_id: group_id))
      Paleolog::Repo.save(Paleolog::Choice.new(name: 'C1', field_id: field_id))
      Paleolog::Repo.save(Paleolog::Choice.new(name: 'C2', field_id: field_id))
      result = repo.all

      assert_equal(%w[C1 C2], result.first.choices.map(&:name))
    end
  end

  describe '#all_for' do
    it 'returns all fields for given ids' do
      field1_id = Paleolog::Repo.save(Paleolog::Field.new(name: 'Field1', group_id: group_id))
      Paleolog::Repo.save(Paleolog::Field.new(name: 'Field2', group_id: group_id))
      result = repo.all_for([field1_id])

      assert_equal([field1_id], result.map(&:id))
    end
  end
end
