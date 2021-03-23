# frozen_string_literal: true

require 'test_helper'

describe Paleolog::Species do
  it 'allows assigning attributes' do
    species = Paleolog::Species.new(
      id: 1,
      group_id: 2,
      name: 'Odontochitina costata',
      verified: true,
      description: 'Short description',
      environment: 'Environment',
      created_at: DateTime.now - 3600,
      updated_at: DateTime.now
    )
    assert_equal 'Odontochitina costata', species.name
  end
end
