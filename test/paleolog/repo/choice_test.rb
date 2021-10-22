# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Choice do
  let(:repo) { Paleolog::Repo::Choice.new }

  after do
    Paleolog::Repo::Field.new.delete_all
    repo.delete_all
  end

  describe '#all_for_field' do
    it 'returns choices for given field id' do
      field = Paleolog::Repo.save(Paleolog::Field.new(name: 'Some field'))
      Paleolog::Repo.save(Paleolog::Choice.new(field: field, name: 'Some choice 1'))
      Paleolog::Repo.save(Paleolog::Choice.new(field: field, name: 'Some choice 2'))
      other_field = Paleolog::Repo.save(Paleolog::Field.new(name: 'Other field'))
      Paleolog::Repo.save(Paleolog::Choice.new(field: other_field, name: 'Other choice'))

      result = repo.all_for_field(field.id)
      assert_equal(['Some choice 1', 'Some choice 2'], result.map(&:name))
    end
  end

  describe '#all_for' do
    let(:field) { Paleolog::Repo.save(Paleolog::Field.new(name: 'Some field')) }
    let(:other_field) { Paleolog::Repo.save(Paleolog::Field.new(name: 'Other field')) }

    before do
      @choice11 = Paleolog::Repo.save(Paleolog::Choice.new(field: field, name: 'Some choice 1'))
      @choice12 = Paleolog::Repo.save(Paleolog::Choice.new(field: field, name: 'Some choice 2'))
      @choice21 = Paleolog::Repo.save(Paleolog::Choice.new(field: other_field, name: 'Other choice 1'))
      @choice22 = Paleolog::Repo.save(Paleolog::Choice.new(field: other_field, name: 'Other choice 2'))
    end

    it 'returns choices for given ids' do
      result = repo.all_for([@choice11.id, @choice22.id])
      assert_equal([@choice11.id, @choice22.id], result.map(&:id))
    end

    it 'returns choices together with field' do
      result = repo.all_for([@choice11.id, @choice22.id])
      assert_equal([field, other_field], result.map(&:field))
    end
  end

  describe '#name_exists_within_field?' do
    it 'checks name uniqueness within field scope' do
      field = Paleolog::Repo.save(Paleolog::Field.new(name: 'Some field'))
      choice = Paleolog::Repo.save(Paleolog::Choice.new(field: field, name: 'Some choice'))

      assert(repo.name_exists_within_field?('Some choice', field.id))
      refute(repo.name_exists_within_field?('Other choice', field.id))
    end

    it 'is case insensitive' do
      field = Paleolog::Repo.save(Paleolog::Field.new(name: 'Some field'))
      choice = Paleolog::Repo.save(Paleolog::Choice.new(field: field, name: 'Some choice'))

      assert(repo.name_exists_within_field?('soMe ChoIce', field.id))
    end
  end
end
