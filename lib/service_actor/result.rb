# frozen_string_literal: true

# Represents the context of an actor, holding the data from both its inputs
# and outputs.

class ServiceActor::Result < BasicObject
  def self.to_result(data)
    return data if data.is_a?(self)

    new(data.to_h)
  end

  %i[class is_a? kind_of? send].each do |method_name|
    define_method(method_name, ::Kernel.instance_method(method_name))
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
  alias pretty_print inspect

  def fail!(failure_class = nil, result = {})
    if failure_class.nil? || failure_class.is_a?(::Hash)
      result = failure_class.to_h
      failure_class = ::ServiceActor::Failure
    end

    data.merge!(result)
    data[:failure] = true

    ::Kernel.raise failure_class, self
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

  def delete!(key)
    data.delete(key)
  end

  def respond_to?(method_name, include_private = false)
    self.class.instance_methods.include?(method_name) ||
      respond_to_missing?(method_name, include_private)
  end

  private

  attr_reader :data

  def respond_to_missing?(method_name, _include_private = false)
    return true if method_name.end_with?("=")
    return true if method_name.end_with?("?") && \
                   data.key?(method_name.to_s.chomp("?").to_sym)
    return true if data.key?(method_name)

    false
  end

  def method_missing(method_name, *args) # rubocop:disable Metrics/AbcSize
    if method_name.end_with?("?") &&
       data.key?(key = method_name.to_s.chomp("?").to_sym)
      value = data[key]
      value.respond_to?(:empty?) ? !value.empty? : !!value
    elsif method_name.end_with?("=")
      data[method_name.to_s.chomp("=").to_sym] = args.first
    elsif data.key?(method_name)
      data[method_name]
    else
      warn_on_undefined_method_invocation(method_name)
    end
  end

  def warn_on_undefined_method_invocation(message)
    ::Kernel.warn(
      "DEPRECATED: Invoking undefined methods on `ServiceActor::Result` will " \
      "lead to runtime errors in the next major release of Actor. " \
      "Invoked method: `#{message}`",
    )
  end
end
