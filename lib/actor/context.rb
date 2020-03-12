# frozen_string_literal: true

class Actor
  # Represents the result of an action.
  class Context
    def self.to_context(data = {})
      data = data.send(:data) if data.is_a?(Actor::Context)

      new(data)
    end

    def initialize(data = {})
      @data = data
    end

    attr_reader :data
    attr_accessor :caller_class

    def ==(other)
      other.class == self.class && data == other.data
    end

    def inspect
      "<ActorContext #{data.inspect} " \
        "inputs: #{caller_class&.inputs&.keys.inspect} " \
        "outputs: #{caller_class&.outputs.inspect}>"
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
      data[:failure?]
    end

    def merge!(new_data)
      data.merge!(new_data.to_hash)

      self
    end

    private

    def method_missing(name, *arguments, **options)
      if name =~ /=$/
        key = name.to_s.sub('=', '').to_sym
        context_set(key, arguments.first)
      elsif data.key?(name)
        context_get(name)
      else
        super
      end
    end

    def respond_to_missing?(name, *_arguments)
      data.key?(name.to_s.sub(/=$/, '').to_sym)
    end

    def allowed_inputs
      return if caller_class.nil?

      caller_class.inputs.keys
    end

    def allowed_outputs
      return if caller_class.nil?

      caller_class.outputs
    end

    def context_get(key)
      if allowed_inputs && !allowed_inputs.include?(key)
        raise NoMethodError,
              "Not allowed to call `.#{key}` on context #{inspect}.\n" \
              "\n" \
              "Try adding an input to your actor, for example:\n" \
              "\n" \
              "  class #{caller_class.name} < Actor\n" \
              "    input #{key.inspect}\n" \
              "  end"
      end

      data[key]
    end

    def context_set(key, value)
      if allowed_outputs && !allowed_outputs.include?(key)
        raise NoMethodError,
              "Not allowed to call `.#{key}=` on context #{inspect}.\n" \
              "\n" \
              "Try adding an output to your actor, for example:\n" \
              "\n" \
              "  class #{caller_class.name} < Actor\n" \
              "    output #{key.inspect}\n" \
              "  end"
      end

      data[key] = value
    end
  end
end
