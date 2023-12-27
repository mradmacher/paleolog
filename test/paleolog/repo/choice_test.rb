# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Choice do
  let(:repo) { Paleolog::Repo::Choice }

  after do
    Paleolog::Repo.delete_all(Paleolog::Field)
    repo.delete_all
  end

  describe '#all_for_field' do
    it 'returns choices for given field id' do
      field_id = Paleolog::Repo.save(Paleolog::Field.new(name: 'Some field'))
      Paleolog::Repo.save(Paleolog::Choice.new(field_id: field_id, name: 'Some choice 1'))
      Paleolog::Repo.save(Paleolog::Choice.new(field_id: field_id, name: 'Some choice 2'))
      other_field_id = Paleolog::Repo.save(Paleolog::Field.new(name: 'Other field'))
      Paleolog::Repo.save(Paleolog::Choice.new(field_id: other_field_id, name: 'Other choice'))

      result = repo.all_for_field(field_id)
      assert_equal(['Some choice 1', 'Some choice 2'], result.map(&:name))
    end
  end

  describe '#all_for' do
    let(:field_id) { Paleolog::Repo.save(Paleolog::Field.new(name: 'Some field')) }
    let(:other_field_id) { Paleolog::Repo.save(Paleolog::Field.new(name: 'Other field')) }

    before do
      @choice11_id = Paleolog::Repo.save(Paleolog::Choice.new(field_id: field_id, name: 'Some choice 1'))
      @choice12_id = Paleolog::Repo.save(Paleolog::Choice.new(field_id: field_id, name: 'Some choice 2'))
      @choice21_id = Paleolog::Repo.save(Paleolog::Choice.new(field_id: other_field_id, name: 'Other choice 1'))
      @choice22_id = Paleolog::Repo.save(Paleolog::Choice.new(field_id: other_field_id, name: 'Other choice 2'))
    end

    it 'returns choices for given ids' do
      result = repo.all_for([@choice11_id, @choice22_id])
      assert_equal([@choice11_id, @choice22_id], result.map(&:id))
    end

    it 'returns choices together with field' do
      result = repo.all_for([@choice11_id, @choice22_id])
      assert_equal([field_id, other_field_id], result.map(&:field_id))
    end
  end

  describe '#name_exists_within_field?' do
    it 'checks name uniqueness within field scope' do
      field_id = Paleolog::Repo.save(Paleolog::Field.new(name: 'Some field'))
      Paleolog::Repo.save(Paleolog::Choice.new(field_id: field_id, name: 'Some choice'))

      assert(repo.name_exists_within_field?('Some choice', field_id))
      refute(repo.name_exists_within_field?('Other choice', field_id))
    end

    it 'is case insensitive' do
      field_id = Paleolog::Repo.save(Paleolog::Field.new(name: 'Some field'))
      Paleolog::Repo.save(Paleolog::Choice.new(field_id: field_id, name: 'Some choice'))

      assert(repo.name_exists_within_field?('soMe ChoIce', field_id))
    end
  end
end
