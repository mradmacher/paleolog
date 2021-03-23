# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Group do
  it 'allows assigning attributes' do
    group = Paleolog::Group.new(id: 1, name: 'Dinoflagellate')
    assert_equal 1, group.id
    assert_equal 'Dinoflagellate', group.name
  end
end
