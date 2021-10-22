# frozen_string_literal: true

require 'test_helper'

module CommonAssertions
  def assert_requires_integer(schema, field)
    result = schema.call(field => nil)
    assert(result.error?(field), "#{field} is nil")
    assert(result.errors[field].include?('must be filled'))

    result = schema.call(field => 'abc')
    assert(result.errors[field].include?('must be an integer'))

    result = schema.call(field => 1)
    refute(result.error?(field))
  end

  def assert_performs_integer_coertion(schema, field)
    result = schema.call(field => '1')
    assert_equal(1, result.to_h[field])
  end

  def assert_requires_string(schema, field)
    result = schema.call(field => nil)
    assert(result.errors[field].include?('must be a string'))

    result = schema.call(field => '')
    assert(result.errors[field].include?('must be filled'))

    result = schema.call(field => '   ')
    assert(result.errors[field].include?('must be filled'))
  end

  def assert_strips_string(schema, field)
    result = schema.call(field => '  some  value   ')
    assert_equal('some  value', result[field])
  end

  def assert_restricts_string_length(schema, field, max: 255)
    result = schema.call(field => 'a' * max)
    refute(result.error?(field))

    result = schema.call(field => 'a' * (max + 1))
    assert(result.errors[field].include?("size cannot be greater than #{max}"))
  end
end
