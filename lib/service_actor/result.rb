# frozen_string_literal: true

require "ostruct"

# Represents the context of an actor, holding the data from both its inputs
# and outputs.
class ServiceActor::Result
  def self.to_result(data)
    return data if data.is_a?(self)

    new(data.to_h)
  end

  def initialize(data = {})
    @data = data.to_h
  end

  def to_h
    data
  end

  def inspect
    "<#{self.class.name} #{to_h}>"
  end

  def fail!(failure_class = nil, result = {})
    if failure_class.nil? || failure_class.is_a?(Hash)
      result = failure_class.to_h
      failure_class = ServiceActor::Failure
    end

    data.merge!(result)
    data[:failure] = true

    raise failure_class, self
  end

  def success?
    !failure?
  end

  def failure?
    data[:failure] || false
  end

  def merge!(result)
    data.merge!(result)

    self
  end

  def key?(name)
    to_h.key?(name)
  end

  def [](name)
    data[name]
  end

  def []=(key, value)
    data[key] = value
  end

  def delete(key)
    data.delete(key)
  end

  # Defined here to override the method on `Object`.
  def display
    to_h.fetch(:display)
  end

  private

  attr_reader :data

  def respond_to_missing?(_method_name, _include_private = false)
    true
  end

  def method_missing(method_name, *args) # rubocop:disable Metrics/AbcSize
    if method_name.end_with?("?")
      value = data[method_name.to_s.chomp("?").to_sym]
      value.respond_to?(:empty?) ? !value.empty? : !!value
    elsif method_name.end_with?("=")
      data[method_name.to_s.chomp("=").to_sym] = args.first
    else
      data[method_name]
    end
  end
end
