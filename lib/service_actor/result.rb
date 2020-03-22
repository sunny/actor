# frozen_string_literal: true

require 'ostruct'

module ServiceActor
  # Represents the result of an actor.
  class Result < OpenStruct
    def self.to_result(data)
      return data if data.is_a?(self)

      new(data.to_h)
    end

    def inspect
      "<#{self.class.name} #{to_h}>"
    end

    def fail!(result = {})
      merge!(result)
      merge!(failure?: true)

      raise Failure, self
    end

    def succeed!(result = {})
      merge!(result)
      merge!(failure?: false)

      raise Success, self
    end

    def success?
      !failure?
    end

    def failure?
      super || false
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

    # Redefined here to override the method on `Object`.
    def display
      to_h.fetch(:display)
    end
  end
end
