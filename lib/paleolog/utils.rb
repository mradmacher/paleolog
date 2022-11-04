# frozen_string_literal: true

require 'singleton'

class None
  def self.defined?
    false
  end

  def self.nil?
    true
  end
end

module Option
  class Some
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end

  class None
    include Singleton
  end

  def self.Some(value)
    Option::Some.new(value)
  end

  def self.None
    Option::None.instance
  end
end

class Result
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def failure?
    false
  end

  def success?
    false
  end
end

class Success < Result
  def success?
    true
  end
end

class Failure < Result
  alias_method :error, :value

  def failure?
    true
  end
end

module Validations
  TRUE_VALUES = %w[1 on On ON t true True TRUE T y yes Yes YES Y].freeze
  FALSE_VALUES = %w[0 off Off OFF f false False FALSE F n no No NO N].freeze

  def self.some_or_none(v)
    case v
    in Option::Some
      v
    in Option::None
      v
    else
      Option.Some(v)
    end
  end

  def self.none(v)
    v.is_a?(Option::None) ? v : Option.None
  end

  Validate = -> (fields, params) {
    result = fields.map { |(key, fn)|
      value = params.key?(key) ? some_or_none(params[key]) : Option.None
      [key, fn.(value)]
    }.to_h

    errors = result.select { |_, v| v.is_a?(Failure) }.map { |k, v| [k, v.error] }.to_h
    if errors.empty?
      params = result.select { |_, v| v.is_a?(Success) && v.value.is_a?(Option::Some) }.map { |k, v| [k, v.value.value] }.to_h
      Success.new(params)
    else
      Failure.new(errors)
    end
  }.curry

  AnyOf = -> (fns, v) {
    fns.reduce(Success.new(v)) { |result, fn| result.is_a?(Failure) ? result : fn.(result.value) }
  }.curry

  Optional = -> (fn, v) {
    case v
    in Option::None
      Success.new(v)
    in Option::Some
      fn.(v)
    end
  }.curry

  Required = -> (fn, v) {
    case v
    in Option::None
      Failure.new(:missing)
    in Option::Some
      fn.(v)
    end
  }.curry

  IncludedIn = -> (collection, v) {
    collection.include?(v.value) ? Success.new(v) : Failure.new(:not_included)
  }.curry

  NilOr = -> (fn, v) {
    v.value.nil? || v.value.is_a?(String) && v.value.strip.empty? ? Success.new(Option.Some(nil)) : fn.(v)
  }.curry

  NotBlank = -> v {
    v.value.nil? || v.value.is_a?(String) && v.value.strip.empty? ? Failure.new(:blank) : Success.new(v)
  }

  Any = -> v { Success.new(v) }

  Gte = -> limit, v { v.value >= limit ? Success.new(v) : Failure.new(:gte) }.curry

  Gt = -> limit, v { v.value > limit ? Success.new(v) : Failure.new(:gt) }.curry

  IsInteger = -> fn, v {
    result = begin
      Integer(v.value)
    rescue
      return Failure.new(:noninteger)
    end
    fn.(Option.Some(result))
  }.curry

  IsBool = -> v {
    case v
    in Option::Some
      if [true, *TRUE_VALUES].include?(v.value)
        Success.new(Option.Some(true))
      elsif [false, *FALSE_VALUES].include?(v.value)
        Success.new(Option.Some(false))
      else
        Failure.new(:nonbool)
      end
    end
  }
end
