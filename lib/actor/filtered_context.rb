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

    def method_missing(name, *arguments, **options)
      return super unless context.respond_to?(name)

      unless available_methods.include?(name)
        raise ArgumentError, "Cannot call #{name} on #{inspect}"
      end

      context.public_send(name, *arguments)
    end

    def respond_to_missing?(name, *_arguments)
      available_methods.include?(name)
    end

    def available_methods
      @available_methods ||=
        readers + setters.map { |key| "#{key}=".to_sym }
    end
  end
end
