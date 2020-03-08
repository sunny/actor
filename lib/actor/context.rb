# frozen_string_literal: true

class Actor
  # Represents the result of an action.
  class Context
    def self.to_context(data = {})
      return data if data.is_a?(Actor::Context)

      new(data)
    end

    def initialize(data = {})
      @data = data.to_hash
    end

    def inspect
      "<ActorContext #{data.inspect}>"
    end

    def fail!(new_data = {})
      merge!(new_data)
      data[:failure?] = true
      raise Actor::Failure, self
    end

    def success?
      !failure?
    end

    def failure?
      !!data[:failure?]
    end

    def merge!(new_data)
      data.merge!(new_data.to_hash)
      self
    end

    def method_missing(name, *arguments, **options)
      if name =~ /=$/
        key = name.to_s.sub('=', '').to_sym
        data[key] = arguments.first
      elsif data.key?(name)
        data[name]
      else
        super
      end
    end

    def respond_to_missing?(name, *_arguments)
      data.key?(name.to_s.sub(/=$/, '').to_sym)
    end

    private

    attr_reader :data
  end
end
