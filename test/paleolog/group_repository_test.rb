# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Repo::Group do
  before do
    @repo = Paleolog::Repo::Group.new
    @repo.delete_all
  end

  it 'persists and finds groups' do
    group = @repo.create(name: 'Dinoflagellate')
    refute_nil group.id
    result = @repo.find(group.id)
    assert_equal result, group

    other_group = @repo.create(name: 'Other')

    result = @repo.all
    assert_equal 2, result.size
    assert_equal result, [group, other_group]
  end
end
