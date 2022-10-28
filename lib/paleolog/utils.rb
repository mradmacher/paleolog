# frozen_string_literal: true

class None
  def self.defined?
    false
  end

  def self.nil?
    true
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
