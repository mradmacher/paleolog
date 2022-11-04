# frozen_string_literal: true

require 'test_helper'

class ValidationTest
  extend Validations
end

describe Validations do
  include Validations
  rules = Validations.validate.(
    counting_id: Validations.required.([Validations.integer)]),
    species_id: Validations.optional.([Validations.integer([Validations.gt(0)])]),
    quantity: Validations.optional.([Validations.nil_or_integer([Validations.gte(0)])]),
    admin: Validations.required.([Validations.bool]),
  )
  result = rules.(counting_id: '10', species_id: '1', quantity: nil, admin: 't')
  p result
end
