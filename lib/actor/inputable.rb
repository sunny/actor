# frozen_string_literal: true

class Actor
  # DSL to document the accepted attributes.
  #
  #   class CreateUser < Actor
  #     input :name
  #     output :name
  #   end
  module Inputable
    # rubocop:disable Naming/MemoizedInstanceVariableName
    def context
      @filtered_context ||= Actor::FilteredContext.new(
        super,
        readers: self.class.inputs.keys,
        setters: self.class.outputs.keys,
      )
    end
    # rubocop:enable Naming/MemoizedInstanceVariableName

    def self.included(base)
      base.extend(ClassMethods)
    end

    # :nodoc:
    module ClassMethods
      def input(name, **arguments)
        inputs[name] = arguments

        define_method(name) do
          context.public_send(name)
        end

        private name
      end

      # :nodoc:
      def inputs
        @inputs ||= {}
      end

      def output(name, **arguments)
        outputs[name] = arguments
      end

      def outputs
        @outputs ||= { error: { type: 'String' } }
      end
    end
  end
end
