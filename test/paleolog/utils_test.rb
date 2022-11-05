# frozen_string_literal: true

require 'test_helper'

describe Validations do
  rules = Validations::Validate.(
    counting_id: Validations::Required.(Validations::IsInteger.(Validations::Any)),
    species_id: Validations::Optional.(Validations::IsInteger.(Validations::Gt.(0))),
    quantity: Validations::Optional.(Validations::NilOr.(Validations::IsInteger.(Validations::Gte.(0)))),
    admin: Validations::Required.(Validations::IsBool),
  )
  result = rules.(counting_id: '10', species_id: '1', quantity: nil, admin: 't')
  p result
end
