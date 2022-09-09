# frozen_string_literal: true

require "ostruct"

# Represents the context of an actor, holding the data from both its inputs
# and outputs.
class ServiceActor::Result < OpenStruct
  def self.to_result(data)
    return data if data.is_a?(self)

    new(data.to_h)
  end

  def inspect
    "<#{self.class.name} #{to_h}>"
  end

  def fail!(failure_class, result = {})
    merge!(result)
    merge!(failure?: true)

    raise failure_class, self
  end

  def success?
    !failure?
  end

  def failure?
    self[:failure?] || false
  end

  def merge!(result)
    result.each_pair do |key, value|
      self[key] = value
    end

    self
  end

  def key?(name)
    to_h.key?(name)
  end

  def [](name)
    to_h[name]
  end

  # Defined here to override the method on `Object`.
  def display
    to_h.fetch(:display)
  end

  private

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.end_with?("?") || super
  end

  def method_missing(symbol, *args)
    attribute = symbol.to_s.chomp("?")

    if symbol.to_s.end_with?("?") && respond_to?(attribute)
      define_singleton_method symbol do
        value = send(attribute.to_sym)

        # Same as ActiveSupport’s #present?
        value.respond_to?(:empty?) ? !value.empty? : !!value
      end

      return send(symbol)
    end

    super symbol, *args
  end
end
