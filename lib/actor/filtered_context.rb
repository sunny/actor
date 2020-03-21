# frozen_string_literal: true

class Actor
  # Represents the result of an action, tied to inputs and outputs.
  class FilteredContext
    def initialize(context, readers:, setters:)
      @context = context
      @readers = readers
      @setters = setters
    end

    def inspect
      "<#{self.class.name} #{context.inspect} " \
        "readers: #{readers.inspect} " \
        "setters: #{setters.inspect}>"
    end

    def fail!(**arguments)
      context.fail!(**arguments)
    end

    def succeed!(**arguments)
      context.fail!(**arguments)
    end

    private

    attr_reader :context, :readers, :setters

    # rubocop:disable Style/MethodMissingSuper
    def method_missing(name, *arguments, &block)
      unless available_methods.include?(name)
        raise Actor::ArgumentError,
              "Cannot call #{name} on #{inspect}"
      end

      context.public_send(name, *arguments, &block)
    end
    # rubocop:enable Style/MethodMissingSuper

    def respond_to_missing?(name, _include_private = false)
      available_methods.include?(name)
    end

    def available_methods
      @available_methods ||=
        readers + setters.map { |key| "#{key}=".to_sym }
    end
  end
end
